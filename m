From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 12:18:44 +0000
Subject: [PATCH 5.10.y-cip] usb: cdns3: gadget: fix state inconsistency on
 gadget init failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-cip-cdns3-510c-v1-1-56e5faa149b9@certik.com>
X-B4-Tracking: v=1; b=H4sIACN1CWsC/1WNSQ7CMAxFr1J5jUscCFW5CmKRwdAglFZxQaCqd
 yeBFcv//rSAcI4scGwWyPyMEsdUBG0a8INNV8YYigat9IFId+jjhD4k2aEh5ZGU6veu602wBKU
 0Zb7E13fwBKYl1b5rBc4/Tx7uxn6uizXtrDC6bJMfKhJOYR7HO1a+/X+Cdf0AJv9l660AAAA=
X-Change-ID: 20261127-cip-cdns3-510c-10094b795da1
To: cip-dev@lists.cip-project.org
Cc: Pavel Machek <pavel@nabladev.com>, 
 Nobuhiro Iwamatsu <nobuhiro.iwamatsu.x90@mail.toshiba>, 
 Ulrich Hecht <uli@fpond.eu>, Yongchao Wu <yongchao.wu@autochips.com>, 
 linux-usb@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795781924; l=3161;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=x04zYySOqW6oAsloCVLgGDTamN9GWZ6GjsXXpIAZjo8=;
 b=jy2jvFay7J6X+CuBJu/uxcCtkOiiTmflG5dxWulypM0ZufJ61IM3kLXa7x27MvK+HqgBZa6Im
 LpVfgGSWdRNDAE2lchqlBhsNdI2BOn+jhL3l3bvwcab0y6qkihQET1X
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Yongchao Wu <yongchao.wu@autochips.com>

commit c32f8748d70c8fc77676ad92ed76cede17bf2c48 upstream.

When cdns3_gadget_start() fails, the DRD hardware is left in gadget mode
while software state remains INACTIVE, creating hardware/software state
inconsistency.

When switching to host mode via sysfs:
  echo host > /sys/class/usb_role/13180000.usb-role-switch/role

The role state is not set to CDNS_ROLE_STATE_ACTIVE due to the error,
so cdns_role_stop() skips cleanup because state is still INACTIVE.
This violates the DRD controller design specification (Figure22),
which requires returning to idle state before switching roles.

This leads to a synchronous external abort in xhci_gen_setup() when
setting up the host controller:

[  516.440698] configfs-gadget 13180000.usb: failed to start g1: -19
[  516.442035] cdns-usb3 13180000.usb: Failed to add gadget
[  516.443278] cdns-usb3 13180000.usb: set role 2 has failed
...
[ 1301.375722] xhci-hcd xhci-hcd.1.auto: xHCI Host Controller
[ 1301.377716] Internal error: synchronous external abort: 96000010 [#1] PREEMPT SMP
[ 1301.382485] pc : xhci_gen_setup+0xa4/0x408
[ 1301.393391] backtrace:
    ...
    xhci_gen_setup+0xa4/0x408    <-- CRASH
    xhci_plat_setup+0x44/0x58
    usb_add_hcd+0x284/0x678
    ...
    cdns_role_set+0x9c/0xbc        <-- Role switch

Fix by calling cdns_drd_gadget_off() in the error path to properly
clean up the DRD gadget state.

Fixes: 7733f6c32e36 ("usb: cdns3: Add Cadence USB3 DRD Driver")
Cc: stable <stable@kernel.org>
Signed-off-by: Yongchao Wu <yongchao.wu@autochips.com>
Acked-by: Peter Chen <peter.chen@kernel.org>
Link: https://patch.msgid.link/20260401001000.5761-1-yongchao.wu@autochips.com
Signed-off-by: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
[ adapted to 5.10.y-cip: use gadget.c and cdns3_drd_gadget_off() ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
5.10 has the old cdns3 layout, so the call goes in gadget.c and uses
cdns3_drd_gadget_off(). This failed to apply to 5.10.y and never made
it into a 5.10.y release, and 5.10.y is now end-of-life, so I'm sending
it here.

Tested on 5.10.275-cip80: the touched object
drivers/usb/cdns3/gadget.o builds with W=1. The same change on
v5.10.275 built with no new W=1 diagnostics and booted under QEMU. I
don't have Cadence hardware, so the failing-init path itself wasn't
exercised.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 drivers/usb/cdns3/gadget.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/usb/cdns3/gadget.c b/drivers/usb/cdns3/gadget.c
index d0378ecd0c98..b6cb690208cd 100644
--- a/drivers/usb/cdns3/gadget.c
+++ b/drivers/usb/cdns3/gadget.c
@@ -3418,6 +3418,7 @@ static int __cdns3_gadget_init(struct cdns3 *cdns)
 	ret = cdns3_gadget_start(cdns);
 	if (ret) {
 		pm_runtime_put_sync(cdns->dev);
+		cdns3_drd_gadget_off(cdns);
 		return ret;
 	}
 

---
base-commit: bd8b111cdf1d9897bf4d826b7305a9c16bfe5f71
change-id: 20261127-cip-cdns3-510c-10094b795da1

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

