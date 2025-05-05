From: George Chan <gchan9527@gmail.com>
Date: Mon, 05 May 2025 17:17:12 +0800
Subject: [PATCH v2 4/5] qcom-phone.env: Example of new env var
 legacy_os_boot_param
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250505-android-boot-v2-4-92dcb5bf59c8@gmail.com>
References: <20250505-android-boot-v2-0-92dcb5bf59c8@gmail.com>
In-Reply-To: <20250505-android-boot-v2-0-92dcb5bf59c8@gmail.com>
To: Tom Rini <trini@konsulko.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Simon Glass <sjg@chromium.org>, Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746436629; l=839;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=HgRzW0yhUc8yhUeP4sq42vjx20KOLqwxVwT8pR9drO4=;
 b=qjYIz76A+Y9bedhQNSPUtQKJkaK9mTv/t3Im1mf0QwgcskFVkTqyrKIXGYuGYASmLrPUY1aVT
 SiBYNbR28OMADjBIEKhI/NuhHR4iMtIc44X4il29B/irQbtAKBWqaBV
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is an example for newly introduced env_var legacy_os_boot_param
that will append 'console=ramoops' to fdt bootargs.

Signed-off-by: George Chan <gchan9527@gmail.com>
---
 board/qualcomm/qcom-phone.env | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/board/qualcomm/qcom-phone.env b/board/qualcomm/qcom-phone.env
index e91ae3ecdfb..536467921d8 100644
--- a/board/qualcomm/qcom-phone.env
+++ b/board/qualcomm/qcom-phone.env
@@ -4,6 +4,10 @@ stdin=serial,button-kbd
 stdout=serial,vidconsole
 stderr=serial,vidconsole
 
+# Introduce var to hold legacy boot param, it will be append 
+# to bootargs automatically
+legacy_os_boot_param=console=ramoops
+
 # Fastboot is keen to use the address from kconfig, but we
 # allocate its buffer at runtime.
 fastboot=fastboot -l $fastboot_addr_r usb 0

-- 
2.43.0

