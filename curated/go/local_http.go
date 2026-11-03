// Go 1.20+: HTTP boundary tested with httptest, an interface, and local files.
// go run local_http.go. No listener, credentials or external service is used.
package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"mime"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

var ErrExists = errors.New("already exists")

type Order struct {
	ID       string `json:"id"`
	Quantity int    `json:"quantity"`
}
type Store interface {
	Put(context.Context, Order) error
}
type FileStore struct{ Directory string }

func (s FileStore) Put(ctx context.Context, order Order) error {
	if err := ctx.Err(); err != nil {
		return err
	}
	file, err := os.OpenFile(filepath.Join(s.Directory, order.ID+".json"), os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
	if errors.Is(err, os.ErrExist) {
		return ErrExists
	}
	if err != nil {
		return err
	}
	// Caller supplies validated IDs. O_EXCL prevents duplicate creation; failed
	// writes are cleaned up. No crash-durability or atomic visibility claim.
	good := false
	defer func() {
		_ = file.Close()
		if !good {
			_ = os.Remove(file.Name())
		}
	}()
	if err = json.NewEncoder(file).Encode(order); err != nil {
		return err
	}
	if err = file.Close(); err != nil {
		return err
	}
	good = true
	return nil
}

var identifier = regexp.MustCompile(`^[a-z0-9-]{1,24}$`)

func Handler(store Store) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			w.Header().Set("Allow", "POST")
			http.Error(w, "method", 405)
			return
		}
		media, _, err := mime.ParseMediaType(r.Header.Get("Content-Type"))
		if err != nil || media != "application/json" {
			http.Error(w, "content type", 415)
			return
		}
		decoder := json.NewDecoder(http.MaxBytesReader(w, r.Body, 512))
		decoder.DisallowUnknownFields()
		var order Order
		if err = decoder.Decode(&order); err != nil {
			http.Error(w, "invalid JSON", 400)
			return
		}
		var trailing any
		if decoder.Decode(&trailing) != io.EOF || !identifier.MatchString(order.ID) || order.Quantity < 1 || order.Quantity > 10 {
			http.Error(w, "invalid order", 400)
			return
		}
		err = store.Put(r.Context(), order)
		switch {
		case errors.Is(err, ErrExists):
			http.Error(w, "duplicate", 409)
		case errors.Is(err, context.Canceled), errors.Is(err, context.DeadlineExceeded):
			http.Error(w, "cancelled", 408)
		case err != nil:
			http.Error(w, "storage failure", 500)
		default:
			w.WriteHeader(201)
		}
	})
}

type StoreFunc func(context.Context, Order) error

func (f StoreFunc) Put(ctx context.Context, order Order) error { return f(ctx, order) }
func check(ok bool) {
	if !ok {
		panic("assertion failed")
	}
}
func request(handler http.Handler, method, body, content string, ctx context.Context) *httptest.ResponseRecorder {
	r := httptest.NewRequest(method, "/orders", strings.NewReader(body)).WithContext(ctx)
	r.Header.Set("Content-Type", content)
	w := httptest.NewRecorder()
	handler.ServeHTTP(w, r)
	return w
}
func main() {
	root, err := os.MkdirTemp("", "http orders with spaces ")
	check(err == nil)
	defer os.RemoveAll(root)
	handler := Handler(FileStore{root})
	ctx := context.Background()
	valid := `{"id":"one","quantity":2}`
	check(request(handler, "POST", valid, "application/json", ctx).Code == 201)
	check(request(handler, "POST", valid, "application/json", ctx).Code == 409)
	bytes, err := os.ReadFile(filepath.Join(root, "one.json"))
	check(err == nil && string(bytes) == valid+"\n")
	for _, body := range []string{"", `[]`, `null`, `{}`, `{"id":"../bad","quantity":1}`, `{"id":"x","quantity":1.5}`, `{"id":"x","quantity":0}`, valid + `{}`, `{"id":"x","quantity":1,"extra":true}`, strings.Repeat("x", 513)} {
		check(request(handler, "POST", body, "application/json", ctx).Code == 400)
	}
	check(request(handler, "GET", valid, "application/json", ctx).Code == 405)
	check(request(handler, "POST", valid, "text/plain", ctx).Code == 415)
	files, err := os.ReadDir(root)
	check(err == nil && len(files) == 1)
	oversized := strings.Repeat(" ", 513) + `{"id":"large","quantity":1}`
	check(request(handler, "POST", oversized, "application/json", ctx).Code == 400)
	_, err = os.Stat(filepath.Join(root, "large.json"))
	check(errors.Is(err, os.ErrNotExist))
	results := make(chan int, 2)
	for i := 0; i < 2; i++ {
		go func() {
			results <- request(handler, "POST", `{"id":"race","quantity":10}`, "application/json", ctx).Code
		}()
	}
	x, y := <-results, <-results
	check((x == 201 && y == 409) || (x == 409 && y == 201))
	cancelled, cancel := context.WithCancel(ctx)
	cancel()
	check(request(handler, "POST", `{"id":"two","quantity":1}`, "application/json", cancelled).Code == 408)
	_, err = os.Stat(filepath.Join(root, "two.json"))
	check(errors.Is(err, os.ErrNotExist))
	called := false
	injected := Handler(StoreFunc(func(c context.Context, _ Order) error { called = true; check(c == cancelled); return c.Err() }))
	check(request(injected, "POST", valid, "application/json", cancelled).Code == 408 && called)
	private := Handler(StoreFunc(func(context.Context, Order) error { return errors.New("secret local path") }))
	response := request(private, "POST", valid, "application/json", ctx)
	check(response.Code == 500 && !strings.Contains(response.Body.String(), "secret"))
	fmt.Println("Local HTTP: methods, strict JSON, interface errors, cancellation and file state passed")
}
