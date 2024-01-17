From: Janne Grunau <j@jannau.net>
Date: Wed, 17 Jan 2024 23:24:27 +0100
Subject: [PATCH RFC 1/6] lib: charset: Fix utf8_to_utf32_stream() return
 value doc string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240117-vidconsole-utf8-uefi-v1-1-539f7ce74fb9@jannau.net>
References: <20240117-vidconsole-utf8-uefi-v1-0-539f7ce74fb9@jannau.net>
In-Reply-To: <20240117-vidconsole-utf8-uefi-v1-0-539f7ce74fb9@jannau.net>
To: Anatolij Gustschin <agust@denx.de>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Simon Glass <sjg@chromium.org>, Andre Przywara <andre.przywara@arm.com>, 
 u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=669; i=j@jannau.net;
 h=from:subject:message-id; bh=8Bj3c/CpUyys+j2k/9GcsKR+Vh5RZAyr/weGo5S8Tqs=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtQVwQveeCzc5eicoDGTYb7reVl1ieLZfhYnttfvVi5ec
 /W8TYhlRykLgxgXg6yYIkuS9ssOhtU1ijG1D8Jg5rAygQxh4OIUgIm0bGVk6NgRyjfvZMLib+sN
 yqLzYmU1mev/2S5K9L5RNP0Ya+aetYwMl1gzFpZ5LOaLVF2o4/p6kkBi7wtrliuXPn568lG2hSW
 TFQA=
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The comment appears to be copied from utf8_to_cp437_stream() but was not
updated.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 include/charset.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/charset.h b/include/charset.h
index 44034c71d3..714382e1c1 100644
--- a/include/charset.h
+++ b/include/charset.h
@@ -328,7 +328,7 @@ int utf8_to_cp437_stream(u8 c, char *buffer);
  *
  * @c:		next UTF-8 character to convert
  * @buffer:	buffer, at least 5 characters
- * Return:	next codepage 437 character or 0
+ * Return:	next Unicode code point or 0
  */
 int utf8_to_utf32_stream(u8 c, char *buffer);
 

-- 
2.43.0

