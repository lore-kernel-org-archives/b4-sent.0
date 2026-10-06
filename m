From: Roland Dreier <rolanddreier@rivian.com>
Subject: [PATCH 0/3] dmaengine: dw-axi-dmac: Fix LLP search, error
 reporting, and error dump
Date: Tue, 06 Oct 2026 01:03:06 +0000
Message-Id: <20261006-dw-axi-fixes-v1-0-3b319e456d93@rivian.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMtIxGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAwMz3ZRy3cSKTN20zIrUYl2TNAMzs0TzFEtzIwMloJaColSwBFBHdCy
 EX1yalJWaXAIyQ6m2FgAWORWdcAAAAA==
X-Change-ID: 20261006-dw-axi-fixes-4f066a7d9720
To: Eugeniy Paltsev <Eugeniy.Paltsev@synopsys.com>, 
 Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: dmaengine@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Roland Dreier <rolanddreier@rivian.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791248589; l=1092;
 i=rolanddreier@rivian.com; s=20260814; h=from:subject:message-id;
 bh=q6zvfoT0mR5ksyINAvycpPFkrs7j+4lxE76e66R9NgU=;
 b=D2nI8YN73HxcoAkFzmSupL94iDZ3YwKRINbA3myVuu6EOuIAxhOXmoI8OiZQOgv1tjiF36bNQ
 bsnVnpbtRhmDzJwq0X/qdleZ4jF1hjLXKRmvi0QuUjMn8PYfN/Yrktx
X-Developer-Key: i=rolanddreier@rivian.com; a=ed25519;
 pk=C7SBXsDIlarq7BpINqyDL67XV/AGNqNt09NCCpFcExk=
X-Endpoint-Received: by B4 Relay for rolanddreier@rivian.com/20260814 with auth_id=952
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

One patch that build's on Jia Wang's fix for error-path LLI dump: the
same bug is present in axi_chan_block_xfer_complete(), although it's
not clear that it could ever be hit in practice, because the llp being
searched for should always be found.

Then two fixes for failed transfer handling: one to report status in
tx_result so that clients can know when a transfer hit an error, and
another to make log messages more informative than "Bad descriptor
submitted".

Signed-off-by: Roland Dreier <rolanddreier@rivian.com>
---
Roland Dreier (3):
      dmaengine: dw-axi-dmac: Bound the cyclic LLP search to the descriptor
      dmaengine: dw-axi-dmac: Report failed transfers in the descriptor result
      dmaengine: dw-axi-dmac: Decode errors in the transfer failure log

 drivers/dma/dw-axi-dmac/dw-axi-dmac-platform.c | 56 +++++++++++++++++++++++---
 1 file changed, 50 insertions(+), 6 deletions(-)
---
base-commit: 67f0943b394d920b6c142aad8c6af94340342ae7
change-id: 20261006-dw-axi-fixes-4f066a7d9720

Best regards,
--  
Roland Dreier <rolanddreier@rivian.com>

