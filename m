From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH v2 0/2] smb: client: reject a too-small tree connect byte
 count
Date: Thu, 20 Aug 2026 21:25:19 -0500
Message-Id: <20260820-b4-disp-58f78a28-v2-0-1fb7a6cb1533@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMPQ6DMAxA4asgz1hKrVIirlIx5McpZgAUF4SEu
 HtDGb/hvQOUs7BCVx2QeROVeSqguoIwuOnDKLEYyNDLWDLonxhFF2xsaq0jiyb61BI19OAAJVs
 yJ9n/y3d/W1c/cvheHzjPH20tTJ50AAAA
X-Change-ID: 20260820-b4-disp-58f78a28-0dbf722521ec
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787279119; l=3146;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=uyR5KdriohoILzKQMgiDjFf+ySUexMpA9o8d0cXrK80=;
 b=lCadI1INMNwMzoFOMmYTqRwGsvzESPiKvK5DKfb6A77i8LAxdm4+w7vhTZTKOgo8Hcf6Y29bT
 zL8E1g+qzADAlwKC0q1bQWft3D2W1HuucKK388Af4xwi8d3fPOhIoDQ
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

v1 was a single patch. The kernel test robot then reported three
-Wconstant-conversion diagnostics in the write path, which Namjae asked about;
they are v1's doing. enum smb_eio_trace is __mode(byte) and its list was
already at 128 entries, so v1's new entry pushed smb_eio_trace_write_too_far to
index 128, which the type cannot hold. clang gives the enum a signed underlying
type and turns that into an error wherever CONFIG_WERROR is set -- x86_64
defconfig sets it -- so v1 alone does not build there. gcc gives the same enum
an unsigned underlying type and says nothing, which is why the tree had not run
into this.

1/2 gives the enum room, 2/2 is v1 unchanged. 1/2 has to land first: 2/2 is what
adds the 129th entry, so on its own it does not build under clang. Stable trees
older than v6.19 have neither smb_EIO2() nor the trace enum, so the backport
there is 2/2's guard with a plain rc = -EIO.

Build A/B at v7.2, W=1, CONFIG_CIFS=m, with gcc 14.2 and clang 19.1.7:

  source state        gcc      clang
  v7.2, unpatched     clean    clean
  2/2 only            clean    3 errors, build fails
  1/2 + 2/2           clean    clean

I dropped the attribute rather than widening it because on x86_64 the record
does not grow either way. The field precedes an unsigned long at offset 8 of
struct trace_event_raw_smb3_eio, so sizeof() is 32 with __mode(byte), with
__mode(HI), and with a plain enum. A plain enum also avoids a spelling the tree
does not use: all 68 __mode() uses in it are __mode(byte).

smb_eio_trace was the only one of those 68 with no room left. rxrpc_abort_reason
has 127 entries.

Two corrections to what v1's changelog said, both prose and not code. The
initialised prefix is 256 bytes rather than the 67 I wrote: header_assemble()
memsets 256 right after cifs_buf_get(), so the byte area only starts past it
from WordCount 111. And the impact was understated -- once bytes_left wraps, the
bound handed to cifs_strndup_from_utf16() reaches 65535 against a ~16 KB
cifs_req_poolp object, so this is a slab out-of-bounds read and not only an
uninitialised one.

checkSMB() is also not what makes the guard sufficient, which is why 2/2 adds no
WordCount check: the parse runs on the request buffer, into which SendReceive()
copies smbCalcSize() bytes, so an honest bytes_left is what keeps the walk
inside the copy. Reproducer is a fake SMB1 server that answers negprot,
completes SESSION_SETUP_ANDX and replies to TREE_CONNECT_ANDX with WordCount 128
and ByteCount 0; KMSAN and KASAN logs on request.

Prior version:
https://lore.kernel.org/all/20260728-b4-disp-6b8e68d4-v1-1-e69277237297@proton.me/

---
Bryam Vargas (2):
      smb: client: let enum smb_eio_trace grow past 128 entries
      smb: client: reject a tree connect response whose byte count is too small

 fs/smb/client/cifssmb.c | 6 ++++++
 fs/smb/client/trace.h   | 3 ++-
 2 files changed, 8 insertions(+), 1 deletion(-)
---
base-commit: 8d3ae59288f1e7d58d76558a6ee96d533bc5019f
change-id: 20260820-b4-disp-58f78a28-0dbf722521ec

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

