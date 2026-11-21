From: Suyuan Wang <shyckless@gmail.com>
Date: Sat, 21 Nov 2026 11:21:13 +0000
Subject: [PATCH net] nfc: only send the SE_IO response to privileged
 listeners
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-nfc-se-io-filter-v1-1-a28b383a6300@gmail.com>
X-B4-Tracking: v=1; b=H4sIAKh+AWsC/yWMwQ6CMBAFf4W8M5vQopXwK8SD1K0uIYV0qzEh/
 LtFjzPJzAblJKzoqw2J36KyxAKmruCft/hgknth2MY6Y6yhGDxpsQsFmTMnak+2u7TO+WY8o2R
 r4iCf33JA5IzrX+prnNjnY4Z9/wLFCu53eQAAAA==
X-Change-ID: 20261121-nfc-se-io-filter-34287366c0b5
To: david@ixit.cz, kuba@kernel.org, edumazet@kernel.org, pabeni@redhat.com, 
 davem@davemloft.net
Cc: oe-linux-nfc@lists.linux.dev, horms@kernel.org, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795260073; l=3495;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=4d8GuF8Ba+/1/ZMaY9xY4YhAq9qRQO0d6gqeD0lMyaA=;
 b=vkTC0F29g8hXjYrSjCLZgj7pbBGIXgpOYAbITdoHdXu6dorCWCCzSy5Gn+PVloXt0hZFJ+7Dz
 5XjXVYnDubNDiwi8tqI1BKFfpI+N+eFulezEa/3aeJ0mHSYwlsVR1oZ
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

NFC_CMD_SE_IO sends an APDU to a secure element and needs CAP_NET_ADMIN
(GENL_ADMIN_PERM). The response from the secure element is not sent
back to the requester, though: se_io_cb() multicasts it with
NFC_ATTR_SE_APDU on the "events" group, and generic netlink lets any
user join that group. So an unprivileged user can read every response
APDU that a privileged process exchanges with the secure element.

The response has to stay on the multicast group, because that is where
userspace reads it: neard's seeld sends NFC_CMD_SE_IO on one socket and
handles the response on the socket it has subscribed to "events".
Requiring CAP_NET_ADMIN for the whole group would also hide the device
and target events from unprivileged listeners.

So keep the multicast, but filter the receivers: deliver the SE_IO
response only to sockets that were opened with CAP_NET_ADMIN in the
initial user namespace, the capability that NFC_CMD_SE_IO itself needs.
The check uses the credentials of the socket's opener, as
do_one_broadcast() does, because se_io_cb() runs in the driver's
context; a socket opened by a privileged process still gets the
response after the process drops the capability or passes the socket
on. Kernel sockets have no file and are skipped. Other events on the
group are not affected.

Found with a static analysis tool and checked by hand.

Fixes: 5ce3f32b5264 ("NFC: netlink: SE API implementation")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
Tested in QEMU (x86_64, KASAN) with a test-only NFC driver whose se_io
answers from a work item. Four listeners subscribe to "events": root;
a socket opened by root that then drops CAP_NET_ADMIN; and two sockets
opened without the capability (root without CAP_NET_ADMIN, nobody).
Root then does DEV_UP (which adds the secure element), ENABLE_SE and
SE_IO.

Before: all four get SE_ADDED and the SE_IO response with the APDU.
After:  root and the socket opened by root get both; the two sockets
        opened without the capability get SE_ADDED only.

Not tested on hardware (st21nfca and st-nci implement se_io).
---
 net/nfc/netlink.c | 16 +++++++++++++++-
 1 file changed, 15 insertions(+), 1 deletion(-)

diff --git a/net/nfc/netlink.c b/net/nfc/netlink.c
index 224bdfa2dd0d..ebacbdd7193b 100644
--- a/net/nfc/netlink.c
+++ b/net/nfc/netlink.c
@@ -1472,6 +1472,19 @@ struct se_io_ctx {
 	u32 se_idx;
 };
 
+/*
+ * Only listeners whose socket was opened with the capability that
+ * NFC_CMD_SE_IO requires get the response APDU. Check the opener of the
+ * socket, as do_one_broadcast() does, since this runs in the driver's
+ * context. Kernel sockets have no file and get nothing.
+ */
+static int se_io_filter(struct sock *dsk, struct sk_buff *skb, void *data)
+{
+	struct file *file = dsk->sk_socket->file;
+
+	return !file || !file_ns_capable(file, &init_user_ns, CAP_NET_ADMIN);
+}
+
 static void se_io_cb(void *context, u8 *apdu, size_t apdu_len, int err)
 {
 	struct se_io_ctx *ctx = context;
@@ -1496,7 +1509,8 @@ static void se_io_cb(void *context, u8 *apdu, size_t apdu_len, int err)
 
 	genlmsg_end(msg, hdr);
 
-	genlmsg_multicast(&nfc_genl_family, msg, 0, 0, GFP_KERNEL);
+	genlmsg_multicast_netns_filtered(&nfc_genl_family, &init_net, msg, 0, 0,
+					 GFP_KERNEL, se_io_filter, NULL);
 
 	kfree(ctx);
 



