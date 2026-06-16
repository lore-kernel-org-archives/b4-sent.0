From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 16 Jun 2026 01:06:12 -0500
Subject: [PATCH] greybus: audio: bound the topology section sizes against
 the fetched size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260616-b4-disp-4352e8b0-v1-1-3e09f62e0ad5@proton.me>
X-B4-Tracking: v=1; b=H4sIANPnMGoC/x3MTQqAIBBA4avErBtQ0yG7SrToZ6rZmChEIN09a
 fkt3iuQOQlnGJoCiW/JcoUK3TawnnM4GGWrBqMMKdKEi8VNckTbOcP9otA67omc944YahYT7/L
 8y3F63w/cNqTYYgAAAA==
To: Mark Greer <mgreer@animalcreek.com>, 
 Vaibhav Agarwal <vaibhav.sr@gmail.com>
Cc: Johan Hovold <johan@kernel.org>, linux-kernel@vger.kernel.org, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 linux-staging@lists.linux.dev, greybus-dev@lists.linaro.org, 
 Alex Elder <elder@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781589971; l=3388;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=7Nd691qGBfOJSIBEQHMHLFIBuWUkCigjnPpH2+uLF24=;
 b=J3dq6yVkfTUOaBX3BnpxsFzk0FIOTk1QZZ/si4FwAg2Dme5nV6K71bOhhu3NQ+r+xEyr+5JtO
 b+Bzx6mJM9kADaYBHURg5Xd7qlL3cYRRSbop7Uvvo73TuzLG9WCkOlT
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

gb_audio_gb_get_topology() fetches a topology blob of a module-supplied
size, and gbaudio_tplg_parse_data() then walks it by adding the
module-supplied size_dais, size_controls and size_widgets fields to
form the control, widget and route section offsets. Those le32 sizes
are never checked against the fetched blob, so a module reporting a
small topology size but large section sizes makes the offsets point
past the allocation, and parsing reads out of bounds.

Reject a topology whose section sizes do not fit within the fetched
size before it is parsed.

Fixes: 184992e305f1 ("greybus: audio: Add Greybus Audio Device Class Protocol helper routines")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
I reproduced the out-of-bounds read both in-kernel under KASAN and with
a userspace AddressSanitizer model of the gbaudio_tplg_process_header()
offset walk. The topology blob is kzalloc(size) where size is
module-supplied (a u16), and process_header() forms control_offset =
&data + size_dais, widget_offset = control_offset + size_controls, etc.;
the consumers then read structs at those offsets.

  - In-kernel (7.1.0-rc5 + KASAN): a 64-byte blob (header 24, so 40 bytes
    available) with size_dais = 44 makes control_offset point 4 bytes
    past the allocation, and reading the first control byte there trips:

      BUG: KASAN: slab-out-of-bounds in ...parse_topology...
      Read of size 1 at addr ...
      ... which belongs to the cache kmalloc-64 of size 64
      The buggy address is located 4 bytes to the right of
       allocated 64-byte region

    The patched arm (sections rejected, -EINVAL) and an in-bounds control
    arm (size_dais = 8) read cleanly with no KASAN report.
  - ASan model (-m32 and -m64): size_dais = 4096 makes control_offset
    point ~4 KB past the 64-byte blob - heap-buffer-overflow READ located
    4056 bytes after the region, both ABIs; patched and in-bounds clean.

The source is a greybus audio module trust boundary (an attacker-supplied
or compromised module reporting a malformed topology); the access is a
read, and a large size_dais sends the offset far enough to fault. The
reproducer (kernel module + ASan model) is available on request.
---
 drivers/staging/greybus/audio_gb.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/staging/greybus/audio_gb.c b/drivers/staging/greybus/audio_gb.c
index 9d8994fdb41a..144591f1a512 100644
--- a/drivers/staging/greybus/audio_gb.c
+++ b/drivers/staging/greybus/audio_gb.c
@@ -37,6 +37,19 @@ int gb_audio_gb_get_topology(struct gb_connection *connection,
 		return ret;
 	}
 
+	/*
+	 * The size_* fields are supplied by the module and are used by
+	 * gbaudio_tplg_parse_data() to compute offsets into the blob; make
+	 * sure the sections fit within the fetched topology, so walking it
+	 * cannot read out of bounds.
+	 */
+	if ((u64)le32_to_cpu(topo->size_dais) + le32_to_cpu(topo->size_controls) +
+	    le32_to_cpu(topo->size_widgets) + le32_to_cpu(topo->size_routes) >
+	    size - sizeof(*topo)) {
+		kfree(topo);
+		return -EINVAL;
+	}
+
 	*topology = topo;
 
 	return 0;

---
base-commit: 8e65320d91cdc3b241d4b94855c88459b91abf66
change-id: 20260616-b4-disp-4352e8b0-45e86659956e

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

