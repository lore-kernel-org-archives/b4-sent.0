From: Moe Mahhouk <moe@flashbots.net>
Date: Sat, 24 Oct 2026 19:17:12 +0000
Subject: [PATCH v3 1/2] virt: tdx-guest: Fix timeout detection in
 wait_for_quote_completion()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-tdx-guest-quote-poll-v3-1-6a83bb767314@flashbots.net>
References: <20261024-tdx-guest-quote-poll-v3-0-6a83bb767314@flashbots.net>
In-Reply-To: <20261024-tdx-guest-quote-poll-v3-0-6a83bb767314@flashbots.net>
To: Kiryl Shutsemau <kas@kernel.org>, 
 Rick Edgecombe <rick.p.edgecombe@intel.com>, 
 Dave Hansen <dave.hansen@linux.intel.com>, 
 Erdem Aktas <erdemaktas@google.com>, Tom Lendacky <thomas.lendacky@amd.com>, 
 Dan Williams <djbw@kernel.org>, 
 Kuppuswamy Sathyanarayanan <sathyanarayanan.kuppuswamy@linux.intel.com>
Cc: Jun Miao <jun.miao@intel.com>, x86@kernel.org, 
 linux-coco@lists.linux.dev, kvm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Moe Mahhouk <moe@flashbots.net>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792869441; l=1997;
 i=moe@flashbots.net; s=20261021; h=from:subject:message-id;
 bh=1dO6LibjB5hJoJz8TEcXao2BEcsRzIPKbgLEX9gGRKg=;
 b=kFo+JKzdDObF9V4MdTRk+Dqjc6ScwZIPR96NM7xblgsfwWLCsglgd8p3ufy+O8PyZ6JAbr0Yq
 b8dpUR3B84iDcV1deEnp3tkRkkOcNwkFtihXvXAnfjWJFFdfVONwT/A
X-Developer-Key: i=moe@flashbots.net; a=ed25519;
 pk=hJTKfjLno/YESrpxMIKDJk34GM+/8Tol+24XK2b4xf0=
X-Endpoint-Received: by B4 Relay for moe@flashbots.net/20261021 with auth_id=1259
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

wait_for_quote_completion() counts the seconds it has waited in i and
reports a timeout when i == timeout. That gets both outcomes of the
last second wrong:

- If the request is still in flight after the last sleep, the loop
  condition increments i once more before it fails, so the loop ends
  with i == timeout + 1 and the function returns 0. The caller then
  returns -EIO instead of -ETIMEDOUT, without the "GetQuote request
  timedout" message. Before commit 0f409eaea53e ("virt: tdx-guest:
  Return error for GetQuote failures") a timed-out request even
  returned success with an empty Quote.

- If the VMM completes the request during the last sleep, the loop ends
  on the status check with i == timeout, and the function returns
  -ETIMEDOUT for a completed request, discarding the Quote.

Decide on the Quote buffer instead: the request timed out if it is
still in flight when the wait ends.

Fixes: f4738f56d1dc ("virt: tdx-guest: Add Quote generation support using TSM_REPORTS")
Cc: stable@vger.kernel.org
Reported-by: Kiryl Shutsemau <kas@kernel.org>
Closes: https://lore.kernel.org/all/atoHWgQF-0vlTRK4@thinkstation/
Reviewed-by: Kiryl Shutsemau (Meta) <kas@kernel.org>
Reviewed-by: Kuppuswamy Sathyanarayanan <sathyanarayanan.kuppuswamy@linux.intel.com>
Signed-off-by: Moe Mahhouk <moe@flashbots.net>
---
 drivers/virt/coco/tdx-guest/tdx-guest.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/virt/coco/tdx-guest/tdx-guest.c b/drivers/virt/coco/tdx-guest/tdx-guest.c
index 11d741da3b35..a5a53174f9d9 100644
--- a/drivers/virt/coco/tdx-guest/tdx-guest.c
+++ b/drivers/virt/coco/tdx-guest/tdx-guest.c
@@ -282,7 +282,7 @@ static int wait_for_quote_completion(struct tdx_quote_buf *buf, u32 timeout)
 			return -EINTR;
 	}
 
-	return (i == timeout) ? -ETIMEDOUT : 0;
+	return (buf->status == GET_QUOTE_IN_FLIGHT) ? -ETIMEDOUT : 0;
 }
 
 static int tdx_report_new_locked(struct tsm_report *report)

-- 
2.34.1

