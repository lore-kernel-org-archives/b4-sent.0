From: Sven Peter <sven@kernel.org>
Subject: [PATCH 0/5] thunderbolt: Fix DP tunnel teardown while an async
 DPRX read is running
Date: Mon, 17 Aug 2026 21:53:57 +0200
Message-Id: <20260817-b4-tbt-fixes-v1-0-eded2461f5fc@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqEMAyF4atI1hNoi5bqVWQWrUaNC5WmMwji3
 a26/Hj87wChyCTQFAdE+rPwumToTwHd5JeRkPtsMMpY5XSFocQUEg68k6A31tXaWaVtDznZIj1
 DLtrva/mFmbp0f8B5XvQhm2twAAAA
X-Change-ID: 20260815-b4-tbt-fixes-a2689186016d
To: Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: asahi@lists.linux.dev, linux-usb@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Konrad Dybcio <konradybcio@kernel.org>, 
 Sven Peter <sven@kernel.org>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1361; i=sven@kernel.org;
 h=from:subject:message-id; bh=37S7RQ5LwNH9nlt1g5IvJLZ1k45TEnNmFes8Iyi3PQw=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1Zz2q09k1njvE6qNuue5nc+kRwmxVC4+ulF9j0dIQ1iZ
 8/4Sod3lLIwiHExyIopsmzfb2/65OEbwaWbLr2HmcPKBDKEgYtTACaSacjwP/Lllg0CIgv9srxn
 TK9YIv323JkAxYCtexoivmq/4Jkn0MTwP9I/v7jpb8nDxwnpl3m226ju2t9V9uhh9TNVAR/tXVf
 6WAA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series contains a bunch of fixes related to teardown while an async
DPRX read is running. I ran into some of these while bringing up the
Apple Silicon NHI and just haven't implemented DP tunneling support yet
such that the DPRX capabilities read can never complete and will always
time out. 

None of it is specific to that hardware though so I figured it
makes sense to already send them out.

Best,

Sven

Signed-off-by: Sven Peter <sven@kernel.org>
---
Sven Peter (5):
      thunderbolt: Fix tunnel reference leak when the DPRX work is not started
      thunderbolt: Hold a switch reference for each path hop
      thunderbolt: Fix domain reference leak when DPRX read is canceled
      thunderbolt: Don't access a DP tunnel after its DPRX read was canceled
      thunderbolt: Cancel the DPRX read when the domain is stopped

 drivers/thunderbolt/path.c   | 21 +++++++++++++++++++++
 drivers/thunderbolt/tb.c     | 23 +++++++++++++++++------
 drivers/thunderbolt/test.c   | 12 ++++++++++++
 drivers/thunderbolt/tunnel.c | 43 ++++++++++++++++++++++++++++++++-----------
 drivers/thunderbolt/tunnel.h |  1 +
 5 files changed, 83 insertions(+), 17 deletions(-)
---
base-commit: 8d3ae59288f1e7d58d76558a6ee96d533bc5019f
change-id: 20260815-b4-tbt-fixes-a2689186016d

Best regards,
--  
Sven Peter <sven@kernel.org>

