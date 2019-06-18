import 'dart:typed_data';

class ByteReader {
  Uint8List _data;
  var _index = 0;

  int get currentIndex => _index;
  int get dataLength => _data.length;

  ByteReader(this._data) {
    assert(_data != null);
  }

  void _require(int byteCount) {
    assert(byteCount != null);
    if (_index + byteCount > _data.length) {
      throw ArgumentError('No more elements');
    }
  }

  int read() {
    _require(1);
    return _data[_index++];
  }

  Uint8List readAll(int byteCount) {
    _require(byteCount);
    var result =
        Uint8List.view(_data.buffer, _data.offsetInBytes + _index, byteCount);
    _index += byteCount;
    return result;
  }
}
