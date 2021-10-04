#main.py
# -*- coding: utf-8 -*-

import win32pipe
import win32file

# 名前付きパイプの作成
pipe = win32pipe.CreateNamedPipe(
    r'\\.\pipe\TestPipe', 
    win32pipe.PIPE_ACCESS_DUPLEX,
    win32pipe. PIPE_TYPE_BYTE | win32pipe.PIPE_READMODE_BYTE | win32pipe.PIPE_WAIT,
    1, 65536, 65536, 0, None)

# クライアントの接続を待つ
win32pipe.ConnectNamedPipe(pipe, None)

# バッファの準備
s = b''

# 無限ループ
while True:
    # パイプから 1 文字読み取って
    hr, c = win32file.ReadFile(pipe, 1)

    # バッファに追加
    s += c
    
    # 改行文字を読んだら
    if c == b'\n':
        # 読み取ったデータを数値に変換して 2 倍する
        x = float(s)
        
        # 結果を文字列に変換
        res = '{0:.3f}\r\n'.format(x)
        
        # コンソールに表示
        print(res, end='')
        
        # パイプに書き込む
        win32file.WriteFile(pipe, res.encode())
        
        # 次の準備
        s = b''
