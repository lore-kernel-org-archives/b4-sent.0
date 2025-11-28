From: Maud Spierings <maudspierings@gocontroll.com>
Date: Fri, 28 Nov 2025 15:08:54 +0100
Subject: [PATCH 3/3] gitignore: ignore *.exe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251128-imx_usb-v1-3-bb6a5180b38e@gocontroll.com>
References: <20251128-imx_usb-v1-0-bb6a5180b38e@gocontroll.com>
In-Reply-To: <20251128-imx_usb-v1-0-bb6a5180b38e@gocontroll.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764339080; l=415;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=rBeLpcpDYXlRocbeFNy26wAbndybequTHRKMHaxq3x4=;
 b=PixO3gC8jd2vxpymDlUm9EtSzJ591AW8fubPh7VLtK0Iv7LWz4xCKhoYuxklx9cuaOt8fOuoG
 8IaFVQcOjJSBzjzlnjeJBAr7pajBou+/7deAZhFepmPfzCWJZyON2Q8
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

windows scripts produce .exe files, which should not be added. Add it to
the gitignore.

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
 .gitignore | 1 +
 1 file changed, 1 insertion(+)

diff --git a/.gitignore b/.gitignore
index a235f9f7de..74cb7b0928 100644
--- a/.gitignore
+++ b/.gitignore
@@ -19,6 +19,7 @@
 *.dcd
 *.dcd.S
 *.elf
+*.exe
 *.i
 *.ko
 *.lex.c

-- 
2.52.0

