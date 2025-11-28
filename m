From: Maud Spierings <maudspierings@gocontroll.com>
Date: Fri, 28 Nov 2025 15:08:52 +0100
Subject: [PATCH 1/3] scripts: common: fix pread_full() for windows
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251128-imx_usb-v1-1-bb6a5180b38e@gocontroll.com>
References: <20251128-imx_usb-v1-0-bb6a5180b38e@gocontroll.com>
In-Reply-To: <20251128-imx_usb-v1-0-bb6a5180b38e@gocontroll.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764339080; l=906;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=ibPWv04zyWFyRhgPhqdcGR/Vsh14YWmSQjpyoJfwofY=;
 b=sJld0JL6e7YwabN+9bJ5JojOuJRsG5XDhCipBwOykCuwpkZHhcw+vguNd+5uc/+QibjpkLWfc
 DF3jTB1NqgaCnHaFoimDJO6CaW8LfZZqApqYLcC/JfgEXjwgK416oJx
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pread() is not available for windows, convert to lseek() + read()

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>

---

I think this modifies the state of fd, I am not sure if pread() did this
too. May be necessary to point the file pointer where it was before? On
the other hand this reads the whole file so why.
---
 scripts/common.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/scripts/common.c b/scripts/common.c
index a6eee968b7..544d295b7f 100644
--- a/scripts/common.c
+++ b/scripts/common.c
@@ -202,8 +202,12 @@ int pread_full(int fd, void *buf, size_t size, loff_t offset)
 	size_t insize = size;
 	int now;
 
+	now = lseek(fd, offset, SEEK_SET);
+	if (now < 0)
+		return now;
+
 	while (size) {
-		now = pread(fd, buf, size, offset);
+		now = read(fd, buf, size);
 		if (now == 0)
 			break;
 		if (now < 0)

-- 
2.52.0

