From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sat, 16 Nov 2024 13:49:36 +0100
Subject: [PATCH v2] input: Documentation: Fix the input_event struct
 documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241116-fix_input_doc-v2-1-133dad7ae928@hotmail.com>
X-B4-Tracking: v=1; b=H4sIAN+UOGcC/3WMQQ6CMBBFr0JmbU2HgIgr7mEIgXZqJ5GWtEg0p
 He3snf5fv57O0QKTBFuxQ6BNo7sXYbyVICyo3uQYJ0ZSllWiCiF4ffAbnmtg/ZKoKbJNJPSrao
 hO0ugfDh69z6z5bj68DnyG/7Wf6UNBYqmqnVtWnmlC3bWr/PIz7PyM/QppS/S7GqQrAAAAA==
X-Change-ID: 20241110-fix_input_doc-1debf7bcd9c5
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: linux-input@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731761407; l=1144;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=aJIAHE62NFe2v1AZvK2w1bKfLBVXM8fqWYWzZ+CLOFQ=;
 b=56Cb4rSIgy+NvQOd/PHdf+aL2L6cfyu5NJvfKmowENuxGlYLjVLJhFsk5KGXwN/FpGqFmp0Bb
 yNMdzsDKyOVCYrl0STxX5krtgAMOKBBq99Bw5ZnFDAkmpE6SaNiRy8S
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix the datatype of the value field of the input_event struct which is
signed instead of unsigned.
See include/uapi/linux/input.h

Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
Changes in v2:
- Fixed the tags in the commit message
- Link to v1: https://lore.kernel.org/r/20241110-fix_input_doc-v1-1-745d5f908e61@hotmail.com
---
 Documentation/input/input.rst | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/input/input.rst b/Documentation/input/input.rst
index 2c67fa904adcf902cebf8e7137c0a1609d879a50..d9a6de87d02de5301500b392191ab67e7db431ed 100644
--- a/Documentation/input/input.rst
+++ b/Documentation/input/input.rst
@@ -264,7 +264,7 @@ events on a read. Their layout is::
 	    struct timeval time;
 	    unsigned short type;
 	    unsigned short code;
-	    unsigned int value;
+	    int value;
     };
 
 ``time`` is the timestamp, it returns the time at which the event happened.

---
base-commit: de2f378f2b771b39594c04695feee86476743a69
change-id: 20241110-fix_input_doc-1debf7bcd9c5

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

