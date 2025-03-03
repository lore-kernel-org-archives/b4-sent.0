From: Patrick Vogelaar <patrick.vogelaar@belden.com>
Date: Mon, 03 Mar 2025 17:35:22 +0100
Subject: [PATCH ][bitbake][scarthgap][2.8] bitbake-diffsigs: fix handling
 when finding only a single sigfile
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250303-backport-2-8-v1-1-e9b2a4122e04@belden.com>
X-B4-Tracking: v=1; b=H4sIAEnaxWcC/x3MQQqDMBBA0avIrJsyjSimVwlZTOKog6BhEkpBv
 HtDl2/x/wWFVbjAu7tA+SNFzqPh9eggbXSsbGRuBot2wB57Eynt+dRqrJnMnNCRw9ENRNCSrLz
 I97/zEHyUGmnn4EsirdtKOXj7nCDc9w+X6PSpeQAAAA==
To: main@lists.openembedded.org
Cc: =?utf-8?q?Enrico_J=C3=B6rns?= <ejo@pengutronix.de>, 
 Richard Purdie <richard.purdie@linuxfoundation.org>, 
 Patrick Vogelaar <patrick.vogelaar@belden.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741019750; l=2704;
 i=patrick.vogelaar@belden.com; s=20240201; h=from:subject:message-id;
 bh=2pmnH8Tjl1idvqHL7k46i5otmOo4LRFy0F96KT1khvU=;
 b=aKYWVaTS+preUZNQqr/sHr+IfFwtTo3Ng8P8havIh4nl7hftd/6lp8MKNhkxLdlyhHREiifWz
 Jy2cbnAXc7DBu4dcXtbV7m9P3Hgswq8e0e1XmmMN0tJeAX6omArJDQ/
X-Developer-Key: i=patrick.vogelaar@belden.com; a=ed25519;
 pk=w0QU8RmOR3hQv1DxMcz6KmySeE8yqbvO0xC1ZSSUNqY=
X-Endpoint-Received: by B4 Relay for patrick.vogelaar@belden.com/20240201 with auth_id=125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Enrico Jörns <ejo@pengutronix.de>

This fixes the following error when calling 'bitbake-dumpsig' or
'bitbake-diffsigs' when having only a single sigfile available:

| Traceback (most recent call last):
|   File "[..]/poky/bitbake/bin/bitbake-dumpsig", line 171, in <module>
|     files = find_siginfo_task(tinfoil, options.taskargs[0], options.taskargs[1])
|             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
|   File "[..]/poky/bitbake/bin/bitbake-dumpsig", line 83, in find_siginfo_task
|     sig2 = latestsigs[1]
|            ~~~~~~~~~~^^^
| IndexError: list index out of range

Handle this by adding (and returning) the path for the second sigfile
only if one is found. This way it will work for both diffsigs and
dumpsig use case.

The calling argparse code already deals with find_siginfo_task()
returning only a single file.
For 'bitbake-dumpsig' it will just dump the single sigfile, for
'bitbake-diffsigs' it will emit a proper error message again:

| ERROR: Only one matching sigdata file found for the specified task (systemd configure)

(cherry picked from commit 25057d33e9131f3214a06bbb316c916c744f8f03)

Signed-off-by: Enrico Jörns <ejo@pengutronix.de>
Signed-off-by: Richard Purdie <richard.purdie@linuxfoundation.org>
Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
---
 bin/bitbake-diffsigs | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)

diff --git a/bin/bitbake-diffsigs b/bin/bitbake-diffsigs
index 8202c7862..9d6cb8c94 100755
--- a/bin/bitbake-diffsigs
+++ b/bin/bitbake-diffsigs
@@ -72,16 +72,17 @@ def find_siginfo_task(bbhandler, pn, taskname, sig1=None, sig2=None):
         elif sig2 not in sigfiles:
             logger.error('No sigdata files found matching %s %s with signature %s' % (pn, taskname, sig2))
             sys.exit(1)
+
+        latestfiles = [sigfiles[sig1]['path'], sigfiles[sig2]['path']]
     else:
         sigfiles = find_siginfo(bbhandler, pn, taskname)
         latestsigs = sorted(sigfiles.keys(), key=lambda h: sigfiles[h]['time'])[-2:]
         if not latestsigs:
             logger.error('No sigdata files found matching %s %s' % (pn, taskname))
             sys.exit(1)
-        sig1 = latestsigs[0]
-        sig2 = latestsigs[1]
-
-    latestfiles = [sigfiles[sig1]['path'], sigfiles[sig2]['path']]
+        latestfiles = [sigfiles[latestsigs[0]]['path']]
+        if len(latestsigs) > 1:
+            latestfiles.append(sigfiles[latestsigs[1]]['path'])
 
     return latestfiles
 

---
base-commit: f6635b32ab553e812fe7c05998ef05834fccd0f3
change-id: 20250303-backport-2-8-dc09a90695aa

Best regards,
-- 
Patrick Vogelaar <patrick.vogelaar@belden.com>

