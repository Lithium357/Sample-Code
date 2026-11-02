// Immutable sorted-table binary codec with canonical varints and CRC32C.
// go run sstable_codec.go
// Format: magic, record count, repeated key-length/value-length/key/value, CRC.
// Limits precede allocations. Decoder owns its byte copies; no aliasing surprises.
package main

import (
	"bytes"
	"encoding/binary"
	"errors"
	"fmt"
	"hash/crc32"
	"math/rand"
	"sort"
)

type Record struct{ Key, Value []byte }

const maxImage = 1 << 20

var crcTable = crc32.MakeTable(crc32.Castagnoli)
var malformed = errors.New("malformed sorted table")

func appendVarint(output []byte, n uint64) []byte {
	var temporary [10]byte
	length := binary.PutUvarint(temporary[:], n)
	return append(output, temporary[:length]...)
}
func Encode(records []Record) ([]byte, error) {
	if len(records) > 10000 {
		return nil, malformed
	}
	output := []byte("SST1")
	output = appendVarint(output, uint64(len(records)))
	for i, record := range records {
		if len(record.Key) == 0 || len(record.Key) > 4096 || len(record.Value) > 65536 {
			return nil, malformed
		}
		if i > 0 && bytes.Compare(records[i-1].Key, record.Key) >= 0 {
			return nil, malformed
		}
		output = appendVarint(output, uint64(len(record.Key)))
		output = appendVarint(output, uint64(len(record.Value)))
		output = append(output, record.Key...)
		output = append(output, record.Value...)
		if len(output) > maxImage-4 {
			return nil, malformed
		}
	}
	checksum := crc32.Checksum(output, crcTable)
	return binary.LittleEndian.AppendUint32(output, checksum), nil
}

type decoder struct {
	data   []byte
	cursor int
}

func (d *decoder) number() (uint64, error) {
	value, n := binary.Uvarint(d.data[d.cursor:])
	if n <= 0 {
		return 0, malformed
	}
	// Reject overlong but numerically equivalent representations.
	var temporary [10]byte
	if binary.PutUvarint(temporary[:], value) != n {
		return 0, malformed
	}
	d.cursor += n
	return value, nil
}
func (d *decoder) take(length uint64) ([]byte, error) {
	if length > uint64(len(d.data)-d.cursor) {
		return nil, malformed
	}
	end := d.cursor + int(length)
	owned := bytes.Clone(d.data[d.cursor:end])
	d.cursor = end
	return owned, nil
}
func Decode(image []byte) ([]Record, error) {
	if len(image) < 9 || len(image) > maxImage || string(image[:4]) != "SST1" {
		return nil, malformed
	}
	payload := image[:len(image)-4]
	if crc32.Checksum(payload, crcTable) != binary.LittleEndian.Uint32(image[len(image)-4:]) {
		return nil, malformed
	}
	d := decoder{data: payload, cursor: 4}
	count, err := d.number()
	if err != nil || count > 10000 {
		return nil, malformed
	}
	// Every record requires at least two varints and one key byte.
	if count > uint64(len(payload)-d.cursor)/3 {
		return nil, malformed
	}
	result := make([]Record, 0, int(count))
	for i := uint64(0); i < count; i++ {
		keySize, err := d.number()
		if err != nil || keySize == 0 || keySize > 4096 {
			return nil, malformed
		}
		valueSize, err := d.number()
		if err != nil || valueSize > 65536 {
			return nil, malformed
		}
		key, err := d.take(keySize)
		if err != nil {
			return nil, err
		}
		value, err := d.take(valueSize)
		if err != nil {
			return nil, err
		}
		if len(result) > 0 && bytes.Compare(result[len(result)-1].Key, key) >= 0 {
			return nil, malformed
		}
		result = append(result, Record{key, value})
	}
	if d.cursor != len(payload) {
		return nil, malformed
	}
	return result, nil
}
func Lookup(records []Record, key []byte) ([]byte, bool) {
	i := sort.Search(len(records), func(i int) bool { return bytes.Compare(records[i].Key, key) >= 0 })
	if i == len(records) || !bytes.Equal(records[i].Key, key) {
		return nil, false
	}
	return bytes.Clone(records[i].Value), true
}
func check(ok bool) {
	if !ok {
		panic("self-check failed")
	}
}
func withCRC(payload []byte) []byte {
	return binary.LittleEndian.AppendUint32(payload, crc32.Checksum(payload, crcTable))
}
func main() {
	source := []Record{{[]byte("alpha"), []byte{0, 1, 2}}, {[]byte("beta"), []byte("two")}, {[]byte("z"), nil}}
	image, err := Encode(source)
	check(err == nil)
	decoded, err := Decode(image)
	check(err == nil)
	encoded, err := Encode(decoded)
	check(err == nil && bytes.Equal(image, encoded))
	value, ok := Lookup(decoded, []byte("beta"))
	check(ok && string(value) == "two")
	value[0] = 'X'
	value, _ = Lookup(decoded, []byte("beta"))
	check(string(value) == "two")
	_, ok = Lookup(decoded, []byte("absent"))
	check(!ok)
	for i := 0; i < len(image); i++ {
		_, err = Decode(image[:i])
		check(err != nil)
		corrupt := bytes.Clone(image)
		corrupt[i] ^= 0x80
		_, err = Decode(corrupt)
		check(err != nil)
	}
	// Checksummed structural corruptions exercise the parser past CRC validation.
	for _, payload := range [][]byte{
		append([]byte("SST1"), 0x80, 0),      // noncanonical count
		append([]byte("SST1"), 1, 0, 0),      // empty key
		append([]byte("SST1"), 0, 99),        // trailing data
		append([]byte("SST1"), 1, 4, 0, 'x'), // truncated key
	} {
		_, err = Decode(withCRC(payload))
		check(err != nil)
	}
	_, err = Encode([]Record{{[]byte("b"), nil}, {[]byte("a"), nil}})
	check(err != nil)
	random := rand.New(rand.NewSource(71))
	for trial := 0; trial < 200; trial++ {
		var records []Record
		for i := 0; i < trial%31; i++ {
			key := []byte(fmt.Sprintf("key%05d", i))
			value := make([]byte, random.Intn(200))
			_, _ = random.Read(value)
			records = append(records, Record{key, value})
		}
		image, err := Encode(records)
		check(err == nil)
		result, err := Decode(image)
		check(err == nil)
		check(len(result) == len(records))
		for i := range records {
			check(bytes.Equal(records[i].Value, result[i].Value))
		}
	}
	fmt.Println("SST codec: canonical encoding, CRC, truncation, ownership and 200 round trips passed")
}
