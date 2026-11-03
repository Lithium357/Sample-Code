// Go 1.20+, standard library. go run conditional_snapshot.go
// A bounded, immutable HTTP representation. Each request gets its own seek
// cursor; HTTP preconditions/ranges are delegated to net/http.ServeContent.
// The fixture calls handlers directly: no listener, DNS or external service.
package main

import (
	"bytes"
	"crypto/sha256"
	"errors"
	"fmt"
	"io"
	"mime"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

var errLimit = errors.New("snapshot byte limit exceeded")
var errInput = errors.New("invalid snapshot reader or limit")

type snapshot struct {
	data     []byte
	etag     string
	modified time.Time
}

func loadSnapshot(source io.Reader, limit int64, modified time.Time) (*snapshot, error) {
	// A non-nil concrete Reader must obey io.Reader and eventually make
	// progress or return an error; this function supplies no I/O deadline.
	if source == nil || limit < 0 || limit > 1<<20 {
		return nil, errInput
	}
	data, err := io.ReadAll(io.LimitReader(source, limit+1))
	if err != nil {
		return nil, err
	} // never publish partial input after failure
	if int64(len(data)) > limit {
		return nil, errLimit
	}
	sum := sha256.Sum256(data)
	return &snapshot{data: data, etag: fmt.Sprintf("\"%x\"", sum), modified: modified}, nil
}

func (s *snapshot) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		w.Header().Set("Allow", "GET, HEAD")
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("ETag", s.etag)
	w.Header().Set("Content-Type", "application/octet-stream")
	// Sharing a bytes.Reader here would share mutable offsets across requests.
	http.ServeContent(w, r, "snapshot.bin", s.modified, bytes.NewReader(s.data))
}

func request(s *snapshot, method string, headers map[string]string) *httptest.ResponseRecorder {
	r := httptest.NewRequest(method, "http://fixture.invalid/snapshot", nil)
	for name, value := range headers {
		r.Header.Set(name, value)
	}
	w := httptest.NewRecorder()
	s.ServeHTTP(w, r)
	return w
}

func require(ok bool, message string) {
	if !ok {
		panic(message)
	}
}

// A legal Reader can return bytes AND a non-EOF error in one call.
type failedReader struct{ err error }

func (r failedReader) Read(p []byte) (int, error) { return copy(p, "partial"), r.err }

func main() {
	original := []byte("name,qty\nalpha,2\nbeta,7\n")
	modified := time.Date(2024, 1, 2, 3, 4, 5, 0, time.UTC)
	// This fixed reference was independently calculated with Python hashlib.
	const expectedTag = "\"cd7713c9ad1ec8a9d0ac2435c9fed34e1739b9ab23049bce8b3c9e76b7af95d9\""
	const expectedDate = "Tue, 02 Jan 2024 03:04:05 GMT"
	s, err := loadSnapshot(bytes.NewReader(original), int64(len(original)), modified)
	require(err == nil && s != nil, "load exact capacity")
	for i := range original {
		original[i] = 'X'
	}
	const expected = "name,qty\nalpha,2\nbeta,7\n"
	full := request(s, "GET", nil)
	require(full.Code == 200 && full.Body.String() == expected, "immutable full body")
	require(full.Header().Get("ETag") == expectedTag, "fixed digest ETag")
	require(full.Header().Get("Last-Modified") == expectedDate, "fixed last-modified date")
	require(full.Header().Get("Content-Length") == strconv.Itoa(len(expected)), "full length")
	head := request(s, "HEAD", nil)
	require(head.Code == 200 && head.Body.Len() == 0, "HEAD body suppressed")
	require(head.Header().Get("ETag") == expectedTag && head.Header().Get("Content-Length") == strconv.Itoa(len(expected)), "HEAD metadata")
	post := request(s, "POST", nil)
	require(post.Code == 405 && post.Header().Get("Allow") == "GET, HEAD" && post.Body.String() == "method not allowed\n", "method rejection")

	cases := []struct {
		name               string
		headers            map[string]string
		code               int
		body, contentRange string
	}{
		{"matching validator", map[string]string{"If-None-Match": expectedTag}, 304, "", ""},
		{"weak matching validator", map[string]string{"If-None-Match": "W/" + expectedTag}, 304, "", ""},
		{"validator list", map[string]string{"If-None-Match": "\"different\", " + expectedTag}, 304, "", ""},
		{"wildcard validator", map[string]string{"If-None-Match": "*"}, 304, "", ""},
		{"mismatch is full", map[string]string{"If-None-Match": "\"different\""}, 200, expected, ""},
		{"modified-since", map[string]string{"If-Modified-Since": expectedDate}, 304, "", ""},
		{"etag takes precedence", map[string]string{"If-None-Match": "\"different\"", "If-Modified-Since": expectedDate}, 200, expected, ""},
		{"If-Match needs strong", map[string]string{"If-Match": "W/" + expectedTag}, 412, "", ""},
		{"If-Match mismatch", map[string]string{"If-Match": "\"different\""}, 412, "", ""},
		{"If-Match succeeds", map[string]string{"If-Match": expectedTag}, 200, expected, ""},
		{"first byte", map[string]string{"Range": "bytes=0-0"}, 206, "n", "bytes 0-0/24"},
		{"middle", map[string]string{"Range": "bytes=5-9"}, 206, "qty\na", "bytes 5-9/24"},
		{"suffix", map[string]string{"Range": "bytes=-4"}, 206, "a,7\n", "bytes 20-23/24"},
		{"clamp last", map[string]string{"Range": "bytes=20-999"}, 206, "a,7\n", "bytes 20-23/24"},
		{"If-Range strong", map[string]string{"Range": "bytes=0-0", "If-Range": expectedTag}, 206, "n", "bytes 0-0/24"},
		{"If-Range weak is full", map[string]string{"Range": "bytes=0-0", "If-Range": "W/" + expectedTag}, 200, expected, ""},
		{"If-Range stale is full", map[string]string{"Range": "bytes=0-0", "If-Range": "\"stale\""}, 200, expected, ""},
		{"cache hit before range", map[string]string{"Range": "bytes=999-", "If-None-Match": expectedTag}, 304, "", ""},
	}
	for _, test := range cases {
		w := request(s, "GET", test.headers)
		require(w.Code == test.code && w.Body.String() == test.body, "conditional/range body: "+test.name)
		require(w.Header().Get("Content-Range") == test.contentRange, "content range: "+test.name)
	}
	for _, value := range []string{"bytes=24-", "bytes=9-2", "bytes=invalid"} {
		w := request(s, "GET", map[string]string{"Range": value})
		require(w.Code == 416, "unsatisfiable/malformed range status")
		// Error text/validator stripping varies with Go versions/GODEBUG.
		// Only a valid unsatisfiable range promises the complete-length header.
		if value == "bytes=24-" {
			require(w.Header().Get("Content-Range") == "bytes */24", "416 resource length")
		}
	}
	multiple := request(s, "GET", map[string]string{"Range": "bytes=0-1,20-23"})
	mediaType, params, err := mime.ParseMediaType(multiple.Header().Get("Content-Type"))
	require(err == nil && multiple.Code == 206 && mediaType == "multipart/byteranges", "multipart metadata")
	reader := multipart.NewReader(multiple.Body, params["boundary"])
	for index, want := range []string{"na", "a,7\n"} {
		part, err := reader.NextPart()
		require(err == nil, "multipart part")
		body, err := io.ReadAll(part)
		require(err == nil && string(body) == want, "multipart bytes")
		expectedRange := []string{"bytes 0-1/24", "bytes 20-23/24"}[index]
		require(part.Header.Get("Content-Range") == expectedRange, "multipart range")
		require(part.Close() == nil, "close MIME part")
	}
	_, err = reader.NextPart()
	require(err == io.EOF, "no extra MIME parts")

	// Empty input, binary byte ranges, failed loads and missing timestamps.
	empty, err := loadSnapshot(strings.NewReader(""), 0, time.Time{})
	require(err == nil && request(empty, "GET", nil).Body.Len() == 0, "empty representation")
	require(request(empty, "GET", nil).Header().Get("Last-Modified") == "", "unknown modification time")
	binary, err := loadSnapshot(bytes.NewReader([]byte{65, 0, 255}), 3, modified)
	require(err == nil && bytes.Equal(request(binary, "GET", map[string]string{"Range": "bytes=1-2"}).Body.Bytes(), []byte{0, 255}), "binary range")
	for _, limit := range []int64{-1, 1<<20 + 1} {
		value, err := loadSnapshot(strings.NewReader(""), limit, modified)
		require(value == nil && err == errInput, "invalid load limit")
	}
	largest := strings.Repeat("x", 1<<20)
	edge, err := loadSnapshot(strings.NewReader(largest), 1<<20, modified)
	require(err == nil && request(edge, "GET", nil).Body.String() == largest, "accepted maximum byte limit")
	tooLarge, err := loadSnapshot(strings.NewReader(largest+"y"), 1<<20, modified)
	require(tooLarge == nil && err == errLimit, "sentinel beyond maximum capacity")
	value, err := loadSnapshot(nil, 3, modified)
	require(value == nil && err == errInput, "nil reader")
	value, err = loadSnapshot(strings.NewReader("x"), 0, modified)
	require(value == nil && err == errLimit, "sentinel over limit")
	failure := errors.New("fixture reader failure")
	value, err = loadSnapshot(failedReader{failure}, 20, modified)
	require(value == nil && err == failure, "failed read does not publish partial representation")
	file, err := os.CreateTemp("", "snapshot-*.bin")
	require(err == nil, "local temp file")
	defer func() { require(os.Remove(file.Name()) == nil, "fixture deletion") }()
	defer file.Close()
	_, err = file.WriteString(expected)
	require(err == nil, "fixture write")
	_, err = file.Seek(0, io.SeekStart)
	require(err == nil, "fixture seek")
	fromFile, err := loadSnapshot(file, 24, modified)
	require(err == nil, "snapshot from file")
	require(file.Close() == nil && request(fromFile, "GET", nil).Body.String() == expected, "snapshot outlives reader")

	var group sync.WaitGroup
	failures := make(chan string, 40)
	for i := 0; i < 40; i++ {
		group.Add(1)
		go func() {
			defer group.Done()
			for j := 0; j < 8; j++ {
				w := request(s, "GET", map[string]string{"Range": "bytes=5-9"})
				if w.Code != 206 || w.Body.String() != "qty\na" {
					failures <- "concurrent seek state shared"
					return
				}
			}
		}()
	}
	group.Wait()
	close(failures)
	for failure := range failures {
		panic(failure)
	}
	fmt.Println("conditional snapshot: validators, ranges, bounds, files and 320 concurrent requests passed")
}
