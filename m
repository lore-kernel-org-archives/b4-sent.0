From: Mani Tofigh <mt4022@columbia.edu>
Subject: [PATCH 0/3] kprobes: Fix optprobe state after forced
 unoptimization
Date: Tue, 03 Nov 2026 13:45:58 -0500
Message-Id: <20261103-kprobes-optprobe-state-v1-0-6aaac612abe6@columbia.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMywqDMBCF4VeRWTuQxAvYVykukji2U8GETCwF8
 d2Ndne+xfl3EEpMAo9qh0RfFg5rga4r8G+7vgh5KgajTK+1anCJKTgSDDHfCyXbTDioyc1d50z
 beyjnmGjm3x1+jn/L5j7k81WD4zgB6lfn23oAAAA=
X-Change-ID: 20261103-kprobes-optprobe-state-90dbf55b246c
To: Masami Hiramatsu <mhiramat@kernel.org>, 
 Naveen N Rao <naveen@kernel.org>
Cc: Steven Rostedt <rostedt@goodmis.org>, 
 "David S. Miller" <davem@davemloft.net>, linux-trace-kernel@vger.kernel.org, 
 linux-kernel@vger.kernel.org, tz2294@columbia.edu, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793731559; l=894;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=v3BKc1evNNgx9JvFdRpY0RryPKMmTA+gZSS3xlFLPnc=;
 b=UQNWImAOO0ZadHFcyte7seIeHtCgwwKU5i3xOSY9AjWFqb2n2xN6rjmcf+6L89qxbdQviYtCT
 rcwjO8HDhwMCYoqvUx9jAyZMZgJFykiu5e2VtSdpTC7nWU7I9yBz/yW
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 06e0d3b89da1 ("kprobes: Make optprobe optimizer
multi-generational and asynchronous") a forced unoptimization can leave
a probe's int3 in the wrong state.  A disabled probe can be freed with
its int3 still in the text, an unhashed probe gets disarmed twice and a
reused probe never gets armed.

Patch 2 relies on patch 1 since it assumes every disabled probe on a
cooling list is already disarmed.

---
Mani Tofigh (3):
      kprobes: Disarm disabled optprobe on forced unoptimization
      kprobes: Do not disarm unhashed optprobe on dispatch
      kprobes: Arm reused optprobe on cooling list

 kernel/kprobes.c | 19 +++++++++++++++++--
 1 file changed, 17 insertions(+), 2 deletions(-)
---
base-commit: d4d028a7ae6401ce70825a3eb663f0a2dfc49db6
change-id: 20261103-kprobes-optprobe-state-90dbf55b246c

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

