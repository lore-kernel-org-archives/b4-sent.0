From: Sven Peter <sven@svenpeter.dev>
Subject: [PATCH 0/4] Apple/PASemi i2c error recovery fixes
Date: Sat, 22 Feb 2025 13:38:32 +0000
Message-Id: <20250222-pasemi-fixes-v1-0-d7ea33d50c5e@svenpeter.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFjTuWcC/x3LQQqAIBBA0avIrBNULKmrRAu1qWaRiQMRSHdPW
 j4+vwJjIWSYRIWCNzFdqUF3AuLh046S1mYwyvTKGCWzZzxJbvQgy1EPMThnlQ0e2pIL/qEd8/K
 +H5oY4NteAAAA
To: Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Andi Shyti <andi.shyti@kernel.org>
Cc: linuxppc-dev@lists.ozlabs.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sven Peter <sven@svenpeter.dev>, 
 Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=914; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=YvDVaUlNxk0FFYVh0Uih/QBxDdTXOT7A8XEjDIMtIh8=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ/rOy5HrJq+aLtY2ozoptL78762o7OM1P5+2PDjD8rfuR
 uLhdnuWjlIWBjEOBlkxRZbt++1Nnzx8I7h006X3MHNYmUCGMHBxCsBEPq9m+B8UVsSsKB6l/aLM
 SGmO1TO/xDc3TO5efhvyobe+eUXa+heMDF84zpXYKKjnr520yNlii5XDksSac68jXTJCt34JMb5
 9nREA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series adds a few fixes/improvements to the error recovery for
Apple/PASemi i2c controllers.
The patches have been in our downstream tree and were originally used
to debug a rare glitch caused by clock strechting but are useful in
general. We haven't seen the controller misbehave since adding these.

Best,

Sven

Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
Hector Martin (3):
      i2c: pasemi: Improve error recovery
      i2c: pasemi: Enable the unjam machine
      i2c: pasemi: Log bus reset causes

Sven Peter (1):
      i2c: pasemi: Add registers bits and switch to BIT()

 drivers/i2c/busses/i2c-pasemi-core.c | 121 ++++++++++++++++++++++++++---------
 1 file changed, 92 insertions(+), 29 deletions(-)
---
base-commit: 2014c95afecee3e76ca4a56956a936e23283f05b
change-id: 20250220-pasemi-fixes-916cb77404ba

Best regards,
-- 
Sven Peter <sven@svenpeter.dev>

