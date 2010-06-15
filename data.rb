#!/usr/bin/ruby

require 'rubygems'
require 'tokyocabinet'
include TokyoCabinet

tdb = TDB.new # ハッシュデータベースを指定

#tdb.tune(131071, 4, 10, 0) # 初期設定
tdb.open('db/data.tct', TDB::OWRITER | TDB::OCREAT) # データの保存先指定など
 
tdb.put('test', 'text' => 'chinko') # key: hoge, value: fuga
p tdb.get('test')       # fuga が返ってくる
 
tdb.close

