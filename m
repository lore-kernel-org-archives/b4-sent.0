From: Suyuan Wang <shyckless@gmail.com>
Subject: [PATCH 0/2] dmaengine: Kill channel tasklets in remove again
Date: Mon, 23 Nov 2026 00:53:05 +0000
Message-Id: <20261123-dma-chancnt-v1-0-f0eea0a4bb63@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHGOA2sC/yXMywqAIBCF4VeJWSekUWCvEi28jDVBFloRhO+e1
 fLjcP4bIgbCCF1xQ8CTIq0+g5cFmEn5ERnZbBCVaDkXNbOLYu9i/M60cqbhUit0EvJjC+jo+mr
 98DseekazvwlI6QErOPqCbwAAAA==
X-Change-ID: 20261123-dma-chancnt-bafc519baef9
To: vkoul@kernel.org, ludovic.desroches@microchip.com
Cc: linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Frank.Li@kernel.org, allen.lkml@gmail.com, dave.jiang@intel.com, 
 dmaengine@vger.kernel.org, andriy.shevchenko@linux.intel.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795395185; l=1164;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=qcysPc3/OLnwjWU/7y9whp4PW1EWxA7jm3IyIBShlQM=;
 b=viPMiyR1BGW2hFR4QUp6sDZ/oVlnod+EWT94IaiABkhtxXpqteeApyZoVak3J+Ov8XDOf1kbz
 G2cnvwMDLk7CRdM9H+PhM9ew+nOFCsTEO/4FGFuCy1NFNEgCPUTXfgz
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

at_xdmac and idma64 kill their channel tasklets in remove() with a loop
over dma.chancnt after dma_async_device_unregister(). Since commit
e81274cd6b52, dma_async_device_unregister() unregisters each channel
and decrements dma.chancnt for it, so chancnt is 0 when the loops run,
they do nothing, and a tasklet scheduled by an interrupt can run after
the devm-allocated driver data is gone. Both patches read the count
before unregistering.

These loops are also touched by Allen's "dmaengine: migrate channel
tasklets to WQ_BH" series (v4, 01/33 and 04/33), which keeps the
chancnt bound. The two fixes don't depend on that series; they make the
current tasklet cleanup work again. Whichever goes in second needs a
trivial rebase.

Found with a static analysis tool and checked by hand. Compile tested
on x86_64 with COMPILE_TEST (W=1); I don't have the hardware.

---
Suyuan Wang (2):
      dmaengine: at_xdmac: Kill the channel tasklets in remove again
      dmaengine: idma64: Kill the channel tasklets in remove again

 drivers/dma/at_xdmac.c | 4 +++-
 drivers/dma/idma64.c   | 4 +++-
 2 files changed, 6 insertions(+), 2 deletions(-)

