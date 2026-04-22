From: Vynnie Von Diktus <vyndiktus@gmail.com>
Date: Wed, 22 Apr 2026 16:16:39 +0000
Subject: [PATCH] qca: Add WCN3990 firmware symlinks for SM8150 (Snapdragon
 855)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-wcn3990-sm8150-fw-symlinks-v1-1-de2a718d7d91@gmail.com>
X-B4-Tracking: v=1; b=H4sIAGb06GkC/yXMwQ6CMAwA0F8hPdukFGacv2I8wChalUlWFQzh3
 516fJe3gElSMdgXCyR5qek9ZpSbAsK5iSdB7bKBibdUM+MUYuU9oQ270hH2E9p7uGm8Gjbe+U7
 IVVw7yMGYpNf5lx+Of9uzvUh4fEdY1w9Eig+xfgAAAA==
X-Change-ID: 20260422-wcn3990-sm8150-fw-symlinks-a959de053245
To: linux-firmware@kernel.org
Cc: Vynnie Von Diktus <vyndiktus@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1794; i=vyndiktus@gmail.com;
 h=from:subject:message-id; bh=/VSTlFsxzPxVgOn0YLYICWy3fZwmvqX6w9hdslJQ900=;
 b=owGbwMvMwCXGn2Ym8lOG8SzjabUkhswXX9I+K31e8Z7D1v/aibRHSgfuqbO+eT1HV2ey+h01j
 eB7LwuLOkpZGMS4GGTFFFlqrnRW3U88wWa5Y8YCmDmsTCBDGLg4BWAill0MfyVYJ5417XzW/tDc
 5N49UaNoha+vFnEEly6YGnZz9fH6AF5Ghjbl6pWV59fubWv8s2wWT/FL4TfvJn1x07jWOWHh39h
 zEYwA
X-Developer-Key: i=vyndiktus@gmail.com; a=openpgp;
 fpr=7CD4897ADF61C80639B898A00F663614F91C01CD
X-Endpoint-Received: by B4 Relay for vyndiktus@gmail.com/default with auth_id=747
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

WCN3990 chips on SM8150 (Snapdragon 855) report controller version 0x01
during Bluetooth init, causing btqca to request qca/crbtfw01.tlv and
qca/crnv01.bin. The same chip on SDM845 reports version 0x21, for which
crbtfw21.tlv and crnv21.bin are already provided.

The firmware content is compatible across both SoC generations; add
symlinks so mainline Linux on SM8150 devices can load Bluetooth firmware
without manual intervention.

Confirmed working on Xiaomi Mi 9 (cepheus, SM8150):
  QCA Patch Version: 0x00006699
  QCA controller version: 0x02241001
  QCA setup on UART is completed

Signed-off-by: Vynnie Von Diktus <vyndiktus@gmail.com>
---
 WHENCE           | 2 ++
 qca/crbtfw01.tlv | 1 +
 qca/crnv01.bin   | 1 +
 3 files changed, 4 insertions(+)

diff --git a/WHENCE b/WHENCE
index a2671e9..3eeb94e 100644
--- a/WHENCE
+++ b/WHENCE
@@ -4981,7 +4981,9 @@ Driver: qca - Qualcomm Atheros Bluetooth support for WCN399x chips
 
 File: qca/crbtfw21.tlv
 Version: BTFM.CHE.2.1.3.c7-00024-QCACHROM-1
+Link: qca/crbtfw01.tlv -> crbtfw21.tlv
 File: qca/crnv21.bin
+Link: qca/crnv01.bin -> crnv21.bin
 File: qca/crbtfw32.tlv
 Version: BTFM.CHE.3.2.0.c2-00044-QCACHROMZ-1
 File: qca/crnv32.bin
diff --git a/qca/crbtfw01.tlv b/qca/crbtfw01.tlv
new file mode 120000
index 0000000..8d4986f
--- /dev/null
+++ b/qca/crbtfw01.tlv
@@ -0,0 +1 @@
+crbtfw21.tlv
\ No newline at end of file
diff --git a/qca/crnv01.bin b/qca/crnv01.bin
new file mode 120000
index 0000000..c3e290f
--- /dev/null
+++ b/qca/crnv01.bin
@@ -0,0 +1 @@
+crnv21.bin
\ No newline at end of file

---
base-commit: 815089bf76d432f937de01da79482705f0d494cf
change-id: 20260422-wcn3990-sm8150-fw-symlinks-a959de053245

Best regards,
--  
Vynnie Von Diktus <vyndiktus@gmail.com>

