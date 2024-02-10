From: Janne Grunau <j@jannau.net>
Date: Sat, 10 Feb 2024 13:46:39 +0100
Subject: [PATCH v2 1/6] lib: charset: Fix and extend utf8_to_utf32_stream()
 documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240210-vidconsole-utf8-uefi-v2-1-88c03db60de2@jannau.net>
References: <20240210-vidconsole-utf8-uefi-v2-0-88c03db60de2@jannau.net>
In-Reply-To: <20240210-vidconsole-utf8-uefi-v2-0-88c03db60de2@jannau.net>
To: Anatolij Gustschin <agust@denx.de>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Simon Glass <sjg@chromium.org>, Andre Przywara <andre.przywara@arm.com>, 
 u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1309; i=j@jannau.net;
 h=from:subject:message-id; bh=YrPQYvhVIvEbmI6hJPScftABwGiEyqsG2EZ/Y+5fk0M=;
 b=kA0DAAoWoRs8240vZWYByyZiAGXHcDqhetona71Qdd5ZmeyfYQfuRJjWpAobL4Bw3S0zNYHYU
 4h1BAAWCgAdFiEEYivpiACrfCFcfeBWoRs8240vZWYFAmXHcDoACgkQoRs8240vZWY0EwD8Dhfr
 kHxjXE5nC2Y4+Wu0Mq/zykQ8SebIjTjtKpktEgIA/3NgBZ9+KZ5p5GkJ+g2GRvArI8WOmnndAyi
 x1gR55k0O
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Suggested-by: Heinrich Schuchardt <xypron.glpk@gmx.de>
Signed-off-by: Janne Grunau <j@jannau.net>
---
 include/charset.h | 14 ++++++++++++--
 1 file changed, 12 insertions(+), 2 deletions(-)

diff --git a/include/charset.h b/include/charset.h
index 44034c71d3..f1050c903d 100644
--- a/include/charset.h
+++ b/include/charset.h
@@ -324,11 +324,21 @@ int utf_to_cp(s32 *c, const u16 *codepage);
 int utf8_to_cp437_stream(u8 c, char *buffer);
 
 /**
- * utf8_to_utf32_stream() - convert UTF-8 stream to UTF-32
+ * utf8_to_utf32_stream() - convert UTF-8 byte stream to Unicode code points
+ *
+ * The function is called for each byte @c in a UTF-8 stream. The byte is
+ * appended to the temporary storage @buffer until the UTF-8 stream in
+ * @buffer describes a Unicode code point.
+ *
+ * When a new code point has been decoded it is returned and buffer[0] is
+ * set to '\0', otherwise the return value is 0.
+ *
+ * The buffer must be at least 5 characters long. Before the first function
+ * invocation buffer[0] must be set to '\0'."
  *
  * @c:		next UTF-8 character to convert
  * @buffer:	buffer, at least 5 characters
- * Return:	next codepage 437 character or 0
+ * Return:	Unicode code point or 0
  */
 int utf8_to_utf32_stream(u8 c, char *buffer);
 

-- 
2.43.0

