From: Nathan Lynch <nathan.lynch@amd.com>
Date: Thu, 10 Oct 2024 12:52:07 -0500
Subject: [PATCH] Documentation: dmaengine: Correct reference to
 glReadPixels()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241010-doc-dmaengine-glreadpixels-v1-1-8202e5834b13@amd.com>
X-B4-Tracking: v=1; b=H4sIAEYUCGcC/xXMwQqEIBRG4VeJu+6CmRPVq0QLR//sQlkoRBC9+
 zjLjwPnoYwkyDRWDyVckuWIBU1dkVttDGDxxaSVNo1SA/vDsd8tYpAIDluC9afc2DL339Z8tOl
 6OE1lcCYspfzn0/y+P0jULq9sAAAA
X-Change-ID: 20241009-doc-dmaengine-glreadpixels-8b3452468ec2
To: Vinod Koul <vkoul@kernel.org>, Jonathan Corbet <corbet@lwn.net>
Cc: dmaengine@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nathan Lynch <nathan.lynch@amd.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728582737; l=1424;
 i=nathan.lynch@amd.com; s=20241010; h=from:subject:message-id;
 bh=sDI7N3mxHAJ03TcvFpl2PcGzAZf7bKpMalFWT9iQmv8=;
 b=C2kVbm9G0oEK8V8c2YVh5mkgs4l3JJMx87pC6fK6biBfp90u3cCU638A9FdaIo3IPPlGudriY
 3Io0jApTASJC251tjhjmU7+fLufEo7UYd5bGXz14PqV2J98qNIQYpzn
X-Developer-Key: i=nathan.lynch@amd.com; a=ed25519;
 pk=ZR637UTGg5YLDj56cxFeHdYoUjPMMFbcijfOkAmAnbc=
X-Endpoint-Received: by B4 Relay for nathan.lynch@amd.com/20241010 with auth_id=241
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The author very likely meant "glReadPixels()" instead of
"glReadpielx()", which does not appear in the OpenGL API.

https://registry.khronos.org/OpenGL-Refpages/gl4/html/glReadPixels.xhtml

Signed-off-by: Nathan Lynch <nathan.lynch@amd.com>
---
 Documentation/driver-api/dmaengine/provider.rst | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/Documentation/driver-api/dmaengine/provider.rst b/Documentation/driver-api/dmaengine/provider.rst
index 3085f8b460fa5514bf95d07e9c7120c19f2d467b..48ad4fd6e2773ab4e4ca5bcb851c0204295ab56f 100644
--- a/Documentation/driver-api/dmaengine/provider.rst
+++ b/Documentation/driver-api/dmaengine/provider.rst
@@ -172,8 +172,8 @@ Currently, the types available are:
   - It's usually used for copying pixel data between host memory and
     memory-mapped GPU device memory, such as found on modern PCI video graphics
     cards. The most immediate example is the OpenGL API function
-    ``glReadPielx()``, which might require a verbatim copy of a huge framebuffer
-    from local device memory onto host memory.
+    ``glReadPixels()``, which might require a verbatim copy of a huge
+    framebuffer from local device memory onto host memory.
 
 - DMA_XOR
 

---
base-commit: 8cf0b93919e13d1e8d4466eb4080a4c4d9d66d7b
change-id: 20241009-doc-dmaengine-glreadpixels-8b3452468ec2

Best regards,
-- 
Nathan Lynch <nathan.lynch@amd.com>

