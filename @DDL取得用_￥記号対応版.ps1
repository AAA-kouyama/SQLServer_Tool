# SQL Server�ڑ��������ݒ� �ڑ���ύX���͂�����ŁI
$Server="AKDB001\AKDB"
$Server_2="AKDB001_AKDB"
$Database="AdfsArtifactStore"
$ConnectionString = "Server=$Server;Database=$Database;Integrated Security=false;UID=sa;PWD=sqls"

# SqlConnection�I�u�W�F�N�g���쐬
$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
$SqlConnection.ConnectionString = $ConnectionString

# �X�g�A�h�v���V�[�W���̈ꗗ���擾����SQL��
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
$SqlCmd.CommandText = "SELECT CONCAT (SPECIFIC_SCHEMA,'.',SPECIFIC_NAME) as name FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' ORDER BY SPECIFIC_SCHEMA, SPECIFIC_NAME"
$SqlCmd.Connection = $SqlConnection

# SqlDataAdapter��DataTable���쐬
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet

# �f�[�^�x�[�X�ɐڑ����ăf�[�^���擾
$SqlConnection.Open()
$SqlAdapter.Fill($DataSet)
$SqlConnection.Close()

#�V�F���t�@�C���̂���ꏊ�ֈړ�����
$path = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $path

# �e�X�g�A�h�v���V�[�W���ɑ΂���DDL���擾
foreach ($Row in $DataSet.Tables[0].Rows) {
    $ProcedureName = $Row["name"]

    # �X�g�A�h�v���V�[�W����DDL���擾����SQL��
    "EXEC sp_helptext '$ProcedureName'"
    $SqlCmd.CommandText = "EXEC sp_helptext '$ProcedureName'"

    # �f�[�^�x�[�X�ɐڑ����ăf�[�^���擾
    $SqlConnection.Open()
    $Reader = $SqlCmd.ExecuteReader()


    # ���ʂ�\��
    $cnt = 1
    while ($Reader.Read()) {
        try {
            #Write-Output $Reader[0] #DEBUG�\���p
            $Reader[0] | Out-File "$Server_2.$Database.$ProcedureName.sql" -Append
            $cnt++
        } catch {
            "$Server_2.$Database.$ProcedureName"+"�ɂĉ��L��"+ $cnt +"�s�ڂ��đ}�������̂Ŋm�F��������" | Out-File "@output_fail.txt" -Append
            $Reader[0] | Out-File "@output_fail.txt" -Append
            Start-Sleep -Milliseconds 10 #�o�͂��Ԃɍ���Ȃ��ꍇ��sleep���Ă݂܂����������Ȃ��̂ŃG���[�g���b�v
            $Reader[0] | Out-File "$Server_2.$Database.$ProcedureName.sql" -Append
        }
    }
    
    try {
        Start-Sleep -Milliseconds 10
        $wordchk = gc "$Server_2.$Database.$ProcedureName.sql" -Raw | % { $_ -replace "`r`n`r`n", "`r`n" }  
        $wordchk | Out-File "$Server_2.$Database.$ProcedureName.sql"
    } catch {
        "�ϊ����G���[�F"+"$Server_2.$Database.$ProcedureName" | Out-File "@output_fail.txt" -Append
    }

    try {
        Start-Sleep -Milliseconds 10
        $wordchk = gc "$Server_2.$Database.$ProcedureName.sql" -Raw | % { $_ -replace "CREATE PROCEDURE", "ALTER PROCEDURE" }  
        $wordchk | Out-File "$Server_2.$Database.$ProcedureName.sql"
    } catch {
        "�ϊ����G���[ Create��F"+"$Server_2.$Database.$ProcedureName" | Out-File "@output_fail.txt" -Append
    }

    # �f�[�^�x�[�X�ڑ�����
    $Reader.Close()
    $SqlConnection.Close()
}
