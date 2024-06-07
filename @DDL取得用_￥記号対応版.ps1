# SQL Server接続文字列を設定 接続先変更時はこちらで！
$Server="AKDB001\AKDB"
$Server_2="AKDB001_AKDB"
$Database="AdfsArtifactStore"
$ConnectionString = "Server=$Server;Database=$Database;Integrated Security=false;UID=sa;PWD=sqls"

# SqlConnectionオブジェクトを作成
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = $ConnectionString

# ストアドプロシージャの一覧を取得するSQL文
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "SELECT CONCAT (SPECIFIC_SCHEMA,'.',SPECIFIC_NAME) as name FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' ORDER BY SPECIFIC_SCHEMA, SPECIFIC_NAME"
$SqlCmd.Connection = $SqlConnection

# SqlDataAdapterとDataTableを作成
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet

# データベースに接続してデータを取得
$SqlConnection.Open()
$SqlAdapter.Fill($DataSet)
$SqlConnection.Close()

#シェルファイルのある場所へ移動する
$path = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $path

# 各ストアドプロシージャに対してDDLを取得
foreach ($Row in $DataSet.Tables[0].Rows) {
    $ProcedureName = $Row["name"]

    # ストアドプロシージャのDDLを取得するSQL文
    "EXEC sp_helptext '$ProcedureName'"
    $SqlCmd.CommandText = "EXEC sp_helptext '$ProcedureName'"

    # データベースに接続してデータを取得
    $SqlConnection.Open()
    $Reader = $SqlCmd.ExecuteReader()


    # 結果を表示
    $cnt = 1
    while ($Reader.Read()) {
        try {
            #Write-Output $Reader[0] #DEBUG表示用
            $Reader[0] | Out-File "$Server_2.$Database.$ProcedureName.sql" -Append
            $cnt++
        } catch {
            "$Server_2.$Database.$ProcedureName"+"にて下記の"+ $cnt +"行目を再挿入したので確認ください" | Out-File "@output_fail.txt" -Append
            $Reader[0] | Out-File "@output_fail.txt" -Append
            Start-Sleep -Milliseconds 10 #出力が間に合わない場合にsleepしてみましたがかわらないのでエラートラップ
            $Reader[0] | Out-File "$Server_2.$Database.$ProcedureName.sql" -Append
        }
    }
    
    try {
        Start-Sleep -Milliseconds 10
        $wordchk = gc "$Server_2.$Database.$ProcedureName.sql" -Raw | % { $_ -replace "`r`n`r`n", "`r`n" }  
        $wordchk | Out-File "$Server_2.$Database.$ProcedureName.sql"
    } catch {
        "変換時エラー："+"$Server_2.$Database.$ProcedureName" | Out-File "@output_fail.txt" -Append
    }

    try {
        Start-Sleep -Milliseconds 10
        $wordchk = gc "$Server_2.$Database.$ProcedureName.sql" -Raw | % { $_ -replace "CREATE PROCEDURE", "ALTER PROCEDURE" }  
        $wordchk | Out-File "$Server_2.$Database.$ProcedureName.sql"
    } catch {
        "変換時エラー Create句："+"$Server_2.$Database.$ProcedureName" | Out-File "@output_fail.txt" -Append
    }

    # データベース接続解除
    $Reader.Close()
    $SqlConnection.Close()
}
