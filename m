From: Sam Day <me@samcday.com>
Date: Wed, 10 Jun 2026 11:27:41 +1000
Subject: [PATCH v3 03/10] binman: section: add AlignUp+PadToAlignment
 helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260610-android-binman-v3-3-710298a38fcc@samcday.com>
References: <20260610-android-binman-v3-0-710298a38fcc@samcday.com>
In-Reply-To: <20260610-android-binman-v3-0-710298a38fcc@samcday.com>
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Alper Nebi Yasak <alpernebiyasak@gmail.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, Bryan Brattlof <bb@ti.com>, 
 Yannic Moog <y.moog@phytec.de>, Wojciech Dubowik <Wojciech.Dubowik@mt.com>, 
 Yegor Yefremov <yegorslists@googlemail.com>, 
 Patrice Chotard <patrice.chotard@foss.st.com>, 
 Heinrich Schuchardt <xypron.glpk@gmx.de>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Rasmus Villemoes <ravi@prevas.dk>, Javier Tia <floss@jetm.me>, 
 Minkyu Kang <mk7.kang@samsung.com>, 
 Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Henrik Grimler <henrik@grimler.se>, yan wang <yan.wang@softathome.com>, 
 Marek Vasut <marex@nabladev.com>, Denis Mukhin <dmukhin@ford.com>, 
 Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781054859; l=986;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=74gwJfk8KZmxEDQsTuqFoX/6rqzJ/dp/PciFvlMRD8Q=;
 b=/9IVlFk4txZUYD/eu7UW1bEvaU9IZ9aC17Akp8onDE+R6ChfvbJ4Jy5C7cvX58Y/zc9z5JF8Y
 6rOcLVMKmMKAuyK/fqutRSXgQab7QJhrN0ZkruwpaPeg2hu8lf4l/Qk
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In the following commits we will be introducing new etypes derived from
Entry_section which need to align values and pad data. To avoid
duplication we introduce the shared helpers here.
---
 tools/binman/etype/section.py | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/tools/binman/etype/section.py b/tools/binman/etype/section.py
index 8530b7ee17f..a8eca3eaf5f 100644
--- a/tools/binman/etype/section.py
+++ b/tools/binman/etype/section.py
@@ -1040,3 +1040,12 @@ class Entry_section(Entry):
             for entry in entries.values():
                 return entry.read_elf_segments()
         return None
+
+    def AlignUp(self, value, align):
+        """Return value aligned to given power of 2"""
+        return (value + align - 1) & ~(align - 1)
+
+
+    def PadToAlignment(self, data, align):
+        """Null-pads given data to given power of 2"""
+        return data + b'\0' * (self.AlignUp(len(data), align) - len(data))

-- 
2.54.0

