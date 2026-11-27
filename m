From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 06:35:09 +0000
Subject: [PATCH 5.15.y] PCI: Free released resource after coalescing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-so5-pci-515-v1-1-58c7cedf2a45@certik.com>
X-B4-Tracking: v=1; b=H4sIAJwkCWsC/02NzQ7CIBCEX6XZs1sBQ237KsYDP6vFGGjYajRN3
 13Qi8f5MvPNCkw5EMPYrJDpGTikWILcNeAmE6+EwZcMSqhOSnVEThpnF1BLjQch/NAPvhedh7K
 YM13C62s7gW6lbt9w/nF+2Bu5papq0xomtNlEN1XEFP2S0h0r3/9dwLZ9ADz0FIOjAAAA
X-Change-ID: 20261127-so5-pci-515-300d989d806d
To: stable@vger.kernel.org
Cc: Ross Lagerwall <ross.lagerwall@citrix.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, linux-pci@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795761308; l=1901;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=Q3ipk5VBhPFIagCrOUrYLKD41qorDNeCk/xbTMJ0NYs=;
 b=g31RX7ICmsUEZ+CZFUWSl48NbQylBjFTR0E9pdvUexHT7lguAnw/pRaFit0c2bLmDD00pzQKA
 ZO7cswPFJrxC82GV/aHHstfGnnqpCmbQhufcf0GThnzs31Beef2+CXu
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Ross Lagerwall <ross.lagerwall@citrix.com>

commit 8ec9c1d5d0a5a4744516adb483b97a238892f9d5 upstream.

release_resource() doesn't actually free the resource or resource list
entry so free the resource list entry to avoid a leak.

Closes: https://lore.kernel.org/r/878r9sga1t.fsf@kernel.org/
Fixes: e54223275ba1 ("PCI: Release resource invalidated by coalescing")
Link: https://lore.kernel.org/r/20230906110846.225369-1-ross.lagerwall@citrix.com
Reported-by: Kalle Valo <kvalo@kernel.org>
Tested-by: Kalle Valo <kvalo@kernel.org>
Signed-off-by: Ross Lagerwall <ross.lagerwall@citrix.com>
Signed-off-by: Bjorn Helgaas <bhelgaas@google.com>
Cc: stable@vger.kernel.org      # v5.16+
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.1.y and newer already have this fix. 5.15.y has the coalescing
prerequisite as 26277a425020.

Tested on v5.15.226:
- x86_64 allmodconfig W=1 build of drivers/pci/probe.o, base vs
  patched, no new warnings
- booted the patched kernel under QEMU/KVM. I didn't have a PCI
  topology that hits the invalidated window path.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

drivers/pci/probe.c | 1 +
 1 file changed, 1 insertion(+)
---
 drivers/pci/probe.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/pci/probe.c b/drivers/pci/probe.c
index 1403b1e50142..d5db12f13a22 100644
--- a/drivers/pci/probe.c
+++ b/drivers/pci/probe.c
@@ -1001,6 +1001,7 @@ static int pci_register_host_bridge(struct pci_host_bridge *bridge)
 		res = window->res;
 		if (!res->flags && !res->start && !res->end) {
 			release_resource(res);
+			resource_list_destroy_entry(window);
 			continue;
 		}
 

---
base-commit: 4f2df9a01754521fbba3493e8ad91ef65515e68c
change-id: 20261127-so5-pci-515-300d989d806d

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

