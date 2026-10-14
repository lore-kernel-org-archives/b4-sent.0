From: Nicholas Velten <nicholasfvelten@gmail.com>
Date: Wed, 14 Oct 2026 08:06:38 -0300
Subject: [PATCH] usb: gadget: u_ether: refuse to re-register a failed
 net_device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-fix-gadget-netdev-reregister-v1-1-0fb91999da06@gmail.com>
X-B4-Tracking: v=1; b=H4sIAD1iz2oC/yXMQQrCMBBG4auUWTuQlKroVcRFmvyJ4yLKTCxC6
 d2Nuvzg8VYyqMDoPKykWMTkUTv8bqB4C7WAJXXT6MaDd37iLG8uIRU0rmgJCysURaxB+biPeXI
 nFzJm6ounove//eX6t73mO2L7PmnbPufLXnKAAAAA
X-Change-ID: 20261014-fix-gadget-netdev-reregister-75cf4090afeb
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 syzbot+85ede281798faf736677@syzkaller.appspotmail.com, 
 Nicholas Velten <nicholasfvelten@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791975997; l=4551;
 i=nicholasfvelten@gmail.com; s=20261014; h=from:subject:message-id;
 bh=R8N/U9EpeodrPP2C8W4xyv5oFcDyRUldfgErXBf/7RE=;
 b=9ZXSnZvhgl4VAmjVXgi0COCcRCK6RUR7/fd0U2D9qtiM2mdmlvSsMVRN4HbiIJp0g3DxStTd8
 7pMKyTgEQm9D731n6qgT6gqe+EN9/T3Z7dov6GndfdCu2MdQELCXtdu
X-Developer-Key: i=nicholasfvelten@gmail.com; a=ed25519;
 pk=WVTZgm6yXQ+XrhULAObg4lwcHPhhxAXrAY+YY6svXzg=
X-Endpoint-Received: by B4 Relay for nicholasfvelten@gmail.com/20261014 with auth_id=1173
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When register_netdevice() fails in or after netdev_register_kobject(),
it returns an error but leaves the net_device in NETREG_UNREGISTERED.
Such a device can never be registered again; the only valid thing to do
with it is free_netdev().

The configfs Ethernet functions (ECM, EEM, NCM, RNDIS and subset)
allocate their net_device once per function instance and register it
from the bind callback, retrying on every bind for as long as the device
is not registered (formerly tracked by a "bound" flag, now by
device_is_registered()). After a failed registration the next bind
therefore calls register_netdev() on an NETREG_UNREGISTERED device and
hits the BUG_ON() at the top of register_netdevice():

  kernel BUG at net/core/dev.c:11440!
  Oops: invalid opcode: 0000 [#1] SMP KASAN NOPTI
  RIP: 0010:register_netdevice+0xc21/0x1d00
  Call Trace:
   register_netdev
   gether_register_netdev
   ncm_bind
   usb_add_function
   configfs_composite_bind
   gadget_bind_driver
   ...
   gadget_dev_desc_UDC_store

syzbot hits this by binding a gadget from a memory cgroup with a tiny
limit, which makes the memcg-accounted allocations in
netdev_register_kobject() fail. That is why its bisection lands on
commit 425b9c7f51c9 ("memcg: accounting for objects allocated for new
netdevice"): that commit made the failure reachable that way, while the
retry itself is much older.

Refuse to register a net_device that is not NETREG_UNINITIALIZED in
gether_register_netdev(), which all of these functions use, so that the
bind fails with -EINVAL instead of crashing. The function instance has
to be recreated to get a usable net_device again.

Reproduced with fail-nth fault injection on the allocations of the
write() to the gadget's UDC attribute, binding again without injection
after each failed bind, using a fresh function instance per iteration:
without this change NCM, ECM and RNDIS hit the BUG_ON() at the 16th
injected allocation; with it, 400 iterations for NCM and 300 each for
ECM, EEM, RNDIS and subset complete with no BUG or KASAN report.

Fixes: 40d133d7f542 ("usb: gadget: f_ncm: convert to new function interface with backward compatibility")
Reported-by: syzbot+85ede281798faf736677@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=85ede281798faf736677
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Nicholas Velten <nicholasfvelten@gmail.com>
---
The syzbot C reproducer did not reach the gadget bind in my virtme-ng
guest (its sandbox setup appears to fail there), so I reproduced with a
small fail-nth program instead. I can post it if useful.

Not tested: architectures other than x86_64, and the legacy (non-configfs)
gadgets that also call gether_register_netdev() (g_ether, g_multi,
g_ffs); they register once from their bind path and should be unaffected.

f_phonet has the same retry pattern but a different outcome:
gphonet_register_netdev() calls free_netdev() on failure while
phonet_opts->net still points at the device and phonet_opts->bound stays
false, so the next bind uses a freed net_device. I left it out of this
patch to keep it to one change and because f_phonet is being changed by
"usb: gadget: f_phonet: fix use-after-free in pn_bind" (v3, not yet
applied); I can send a separate fix on top of that if wanted.

Also touching gether_register_netdev(), without conflict:
"usb: gadget: u_ether: Fix NULL pointer deref in debug logging".
---
 drivers/usb/gadget/function/u_ether.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/usb/gadget/function/u_ether.c b/drivers/usb/gadget/function/u_ether.c
index 59d85d6a8..1f4ac7078 100644
--- a/drivers/usb/gadget/function/u_ether.c
+++ b/drivers/usb/gadget/function/u_ether.c
@@ -865,6 +865,17 @@ int gether_register_netdev(struct net_device *net)
 
 	if (!net->dev.parent)
 		return -EINVAL;
+
+	/*
+	 * A register_netdev() that failed after netdev_register_kobject()
+	 * leaves the device NETREG_UNREGISTERED, and it can never be
+	 * registered again. The function drivers retry on every bind while
+	 * the device is not registered, so refuse instead of hitting the
+	 * BUG_ON() in register_netdevice().
+	 */
+	if (net->reg_state != NETREG_UNINITIALIZED)
+		return -EINVAL;
+
 	dev = netdev_priv(net);
 	g = dev->gadget;
 

---
base-commit: a90ee4305c4a5df72c11b31dacfdc76e00fcf78a
change-id: 20261014-fix-gadget-netdev-reregister-75cf4090afeb

Best regards,
--  
Nicholas Velten <nicholasfvelten@gmail.com>

