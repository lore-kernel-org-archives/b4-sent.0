From: Janne Grunau <j@jannau.net>
Date: Sat, 16 Mar 2024 22:50:18 +0100
Subject: [PATCH v3 1/7] lib: charset: Fix and extend utf8_to_utf32_stream()
 documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240316-vidconsole-utf8-uefi-v3-1-4e8a3d349447@jannau.net>
References: <20240316-vidconsole-utf8-uefi-v3-0-4e8a3d349447@jannau.net>
In-Reply-To: <20240316-vidconsole-utf8-uefi-v3-0-4e8a3d349447@jannau.net>
To: Anatolij Gustschin <agust@denx.de>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>
Cc: Simon Glass <sjg@chromium.org>, Andre Przywara <andre.przywara@arm.com>, 
 u-boot@lists.denx.de, Janne Grunau <j@jannau.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1364; i=j@jannau.net;
 h=from:subject:message-id; bh=GGDZzVt5+3XbxA+40cxNNbp+I7PDL3t7DkDHx2HZSBs=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhtRvIvJ8p0v/Xjrw6KKw4o2PZyrzGs6Wf7ffJsJ2l8vt3
 /X3mrk2HaUsDGJcDLJiiixJ2i87GFbXKMbUPgiDmcPKBDKEgYtTACZitpWR4eipI8ePX76x/vHv
 +ODU42tiPCwU/5o8sQm9+n2nDXN8pibDP/tX88RyF8SITJt7OPKqnw3b71i7WLOZc8Q1V/71+lz
 wlhMA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Suggested-by: Heinrich Schuchardt <xypron.glpk@gmx.de>
Reviewed-by: Heinrich Schuchardt <xypron.glpk@gmx.de>
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
2.44.0

