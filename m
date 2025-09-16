From: Arturs Artamonovs <Arturs.Artamonovs@analog.com>
Date: Tue, 16 Sep 2025 16:57:17 +0100
Subject: [PATCH] tty: serial: fix help message for SERIAL_CPM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250916-tty-serial-kconfig-fix-v1-1-f603824e494a@analog.com>
X-B4-Tracking: v=1; b=H4sIANyIyWgC/x2MQQqAIBAAvxJ7bkGXJOor0UF0q6Ww0Igi+nvWc
 QZmbkgchRO0xQ2RD0myhgy6LMBNNoyM4jMDKTKq0Qb3/cKvsQvObg2DjDjIiVVtjSLfKKsJcrx
 Fzvofd/3zvAvBfoJoAAAA
X-Change-ID: 20250915-tty-serial-kconfig-fix-47a502d90a12
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 Arturs Artamonovs <Arturs.Artamonovs@analog.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1758038243; l=1155;
 i=Arturs.Artamonovs@analog.com; s=20240910; h=from:subject:message-id;
 bh=yjMgUPZ9DVsVDd5Qs/QLwakOMWYigatGAbBXRitE/vs=;
 b=kAiOk5rg5tzci+cACspD0J4h1CKJQrhFLIiuBO3TT7JXCAoMBeX2SmwGDbZpRwXcb53i+6sRk
 qxS1DrUMssMBYLQm2MhDXhCJo2Ph6lV+jGsnWOWAxURVmCeuWTIwQNu
X-Developer-Key: i=Arturs.Artamonovs@analog.com; a=ed25519;
 pk=UXODIid/MrmBXvqkX4PeEfetDaNAw9xKMINHIc5oZCk=
X-Endpoint-Received: by B4 Relay for Arturs.Artamonovs@analog.com/20240910 with auth_id=327
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Running checkpatch reported error extra whitespace at the
end of help message for SERIAL_CPM menu entry

Signed-off-by: Arturs Artamonovs <Arturs.Artamonovs@analog.com>
---
Running checkpath.pl on drivers/tty/serial reports error
Removing white space at the end of the line in Kconfig for SERIAL_CPM entry
---
 drivers/tty/serial/Kconfig | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/tty/serial/Kconfig b/drivers/tty/serial/Kconfig
index 44427415a80d7da63a8f2328b1932bff48500974..ac690f5cfbfe870a0c7eed4dc974d6ec28bb2c5f 100644
--- a/drivers/tty/serial/Kconfig
+++ b/drivers/tty/serial/Kconfig
@@ -782,7 +782,7 @@ config SERIAL_CPM
 	depends on CPM2 || CPM1
 	select SERIAL_CORE
 	help
-	  This driver supports the SCC and SMC serial ports on Motorola 
+	  This driver supports the SCC and SMC serial ports on Motorola
 	  embedded PowerPC that contain a CPM1 (8xx) or CPM2 (8xxx)
 
 config SERIAL_CPM_CONSOLE

---
base-commit: f83ec76bf285bea5727f478a68b894f5543ca76e
change-id: 20250915-tty-serial-kconfig-fix-47a502d90a12

Best regards,
-- 
Arturs Artamonovs <Arturs.Artamonovs@analog.com>

