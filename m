From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 20 Aug 2026 21:25:20 -0500
Subject: [PATCH v2 1/2] smb: client: let enum smb_eio_trace grow past 128
 entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260820-b4-disp-58f78a28-v2-1-1fb7a6cb1533@proton.me>
References: <20260820-b4-disp-58f78a28-v2-0-1fb7a6cb1533@proton.me>
In-Reply-To: <20260820-b4-disp-58f78a28-v2-0-1fb7a6cb1533@proton.me>
To: Steve French <sfrench@samba.org>
Cc: Paulo Alcantara <pc@manguebit.org>, Namjae Jeon <linkinjeon@kernel.org>, 
 Shyam Prasad N <sprasad@microsoft.com>, 
 Ronnie Sahlberg <ronniesahlberg@gmail.com>, 
 David Howells <dhowells@redhat.com>, Nathan Chancellor <nathan@kernel.org>, 
 Tom Talpey <tom@talpey.com>, llvm@lists.linux.dev, 
 Bharath SM <bharathsm@microsoft.com>, linux-cifs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, samba-technical@lists.samba.org, 
 Jeff Layton <jlayton@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787279119; l=1542;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=YvTTyIT31HzfaHafhvdDaEF4Yp7y/hBcBtCYI66qIN0=;
 b=+fmSYrkWQ/ibMuxZoOEsck2vdKIXuyZrUtH2QNbeuIaeo7CHWxQxBW9qmG8ba92a7DP3Tr4SH
 3PbT331+1oSB7oS4CDzWfHe/C2Sws3RnNq5YPIL9LM/2qg9AQXVMsby
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

enum smb_eio_trace is __mode(byte) and the list has held exactly 128
entries since it was added, so the last sits at index 127 and a 129th has
no representable value.  clang gives the enum a signed underlying type and
converts the overflowing value to -128; x86_64 defconfig turns that into a
build failure because it sets CONFIG_WERROR=y, and where it does not, the
value stops matching the __print_symbolic() table and those events print a
raw number.  gcc picks an unsigned underlying type and reports nothing.

Drop the attribute.  On x86_64 the record does not grow: the field
precedes an unsigned long at offset 8 of struct trace_event_raw_smb3_eio,
so sizeof() stays 32 either way.

Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202607290344.fvDmgRPA-lkp@intel.com/
Fixes: f80ac7eda1cf ("cifs: Add a tracepoint to log EIO errors")
Cc: stable@kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 fs/smb/client/trace.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/smb/client/trace.h b/fs/smb/client/trace.h
index 5b21ad3c15fb..0a91d3aaa079 100644
--- a/fs/smb/client/trace.h
+++ b/fs/smb/client/trace.h
@@ -213,7 +213,7 @@
 #define EM(a, b) a,
 #define E_(a, b) a
 
-enum smb_eio_trace		{ smb_eio_traces } __mode(byte);
+enum smb_eio_trace		{ smb_eio_traces };
 enum smb3_rw_credits_trace	{ smb3_rw_credits_traces } __mode(byte);
 enum smb3_tcon_ref_trace	{ smb3_tcon_ref_traces } __mode(byte);
 

-- 
2.55.0

