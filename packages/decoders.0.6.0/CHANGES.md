## 0.6.0 (2021-03-12)

* Add `Decode.of_of_string` and `Encode.of_to_string` (@mattjbray)
* Add `Decode.array` with bs-specific impl (#28, #30, @actionshrimp)

## 0.5.0 (2020-10-28)

* Add `Decoders_msgpck` (#26, @c-cube)
* Add `let` operators (#24, @c-cube)
* Alias `Decode.map` as `<$>` (#21, @hamza0867)

## 0.4.0 (2020-05-06)

* Expose `null` decoder (#18, @mattjbray)
* Rename `Encode.option` to `Encode.nullable` (#19, @mattjbray)
* Add `Decoders_jsonm` (#20, @mattjbray)

## 0.3.0 (2019-06-24)

* Add `uncons` primitive (#7, @mattjbray)
* Add `Decoders_sexplib` (#7, @mattjbray)
* Add `Decoders_cbor` (#9, @mattjbray)
* Add `Decoders_bencode` (#14, @c-cube)
* Remove `containers` dependency (#16, @c-cube)

## 0.2.0 (2019-06-24)

* Add `field_opt` decoder (#5, @actionshrimp)
* Add `list_fold_left` decoder (#8, @ewenmaclean)

## 0.1.2 (2019-01-09)

* Upgrade from `jbuilder` to `dune`
* Remove `cppo` build dependency (#4)

## 0.1.1 (2018-12-13)

* Fix some non-tail-recursive stuff.
* Add `stringlit` encoder and decoder for `Decoders_yojson.Raw`

## 0.1.0 (2018-09-26)

Initial release.
