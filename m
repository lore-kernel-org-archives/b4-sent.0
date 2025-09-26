From: Dominique Martinet <asmadeus@codewreck.org>
Subject: [PATCH 0/3] Split patches sent earlier
Date: Fri, 26 Sep 2025 18:27:28 +0900
Message-Id: <20250926-v9fs_misc-v1-0-a8b3907fc04d@codewreck.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIBc1mgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDSyMz3TLLtOL43MziZF1jM2Mjg8TUNAuLFEsloPqCotS0zAqwWdGxtbU
 As/KtgFsAAAA=
X-Change-ID: 20250926-v9fs_misc-36320aef88d9
To: "Randall P. Embry" <rpembry@gmail.com>, 
 Eric Van Hensbergen <ericvh@kernel.org>, 
 Latchesar Ionkov <lucho@ionkov.net>, 
 Christian Schoenebeck <linux_oss@crudebyte.com>
Cc: v9fs@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Dominique Martinet <asmadeus@codewreck.org>
X-Mailer: b4 0.15-dev-7be4f
X-Developer-Signature: v=1; a=openpgp-sha256; l=878; i=asmadeus@codewreck.org;
 h=from:subject:message-id; bh=qfXgb+yYLhRa2IcpPHI2iywFY1Y2Fm3oR9YEiLZQd44=;
 b=owEBbQKS/ZANAwAKAatOm+xqmOZwAcsmYgBo1lyH+7NBIAYbEA8NOLVRhtoIVCFkD0YMEyn5K
 r+Ga74xinqJAjMEAAEKAB0WIQT8g9txgG5a3TOhiE6rTpvsapjmcAUCaNZchwAKCRCrTpvsapjm
 cNIMD/9ZXhaWrq3pKI+K2orBC21oEcSf3qlXPhQsbLpLxWhfabSaDWI6ojpw3uDrNLGduPo2iAy
 IRRZbEUMFia2kPXomFhhG52rbAWJyT6AYqwzMqsJfcR6NEhX05pP81H/X1nPbqKBN7hKZFAMZVu
 d7/3OeDnIpkoXGGMtwa5WBhA8LAjC7aG5iUr9AEUGE4xf/nOgcjXoB5nZTT0KHBFbzplttMDdt2
 Qo65psDVWdEpH1LlQ3aocA5YK3GarAR3yIfn6c+y4CHMPNoWMoNHTRxLJQpxL7SftONwvbvdIn0
 1iKCTqDasoYu/8YQqXIht30F+9Fsn1o/YEyn94AimHbZEDzsIOzRfFOIX8moP9QGrd7DF78whh4
 iqR4tlotSm12eILBaf/c6X2ep4g/Oh4RNV7yzaMGyBDRX4w6oWs1rgtp/po3FH90qFg71v7pD8U
 sTlrJeB3LzQsmFqjNDrU5KMq/iVQk9QgJUWbbwMQEsPqQ96oPyzHHg/ev+dC3qIbgugb/XuFNFf
 HTWxun331eeqtcJot7tw+WsVVY0vUAOU3bWZx5OhSlh7ddVhZkuOwIufxfjV+IAjSTkITf1DTWz
 /WGWbWCby2YXTtDPuUtCYx6taI8oaZT9qt5aosrvLhzr4wgOngxoa1fH/djuBj0R0cfQyfwWFfC
 bhPcsEbD/K2/SWg==
X-Developer-Key: i=asmadeus@codewreck.org; a=openpgp;
 fpr=B894379F662089525B3FB1B9333F1F391BBBB00A
X-Endpoint-Received: by B4 Relay for asmadeus@codewreck.org/default with auth_id=435
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This was a pretty simple patch overall but "bullet point" commits are
not great for later debugging, so just split this commit in 3:
https://lkml.kernel.org/r/20250925122802.72580-1-rpembry@gmail.com

Randall, I kept you as author, so please comment if you have anything to
say about commit messages or anything else, and I'll pick these up and
push to Linus in a couple of weeks.

Signed-off-by: Dominique Martinet <asmadeus@codewreck.org>
---
Randall P. Embry (3):
      9p: clean up comment typos
      9p: fix /sys/fs/9p/caches overwriting itself
      9p: sysfs_init: don't hardcode error to ENOMEM

 fs/9p/v9fs.c | 16 +++++++++-------
 1 file changed, 9 insertions(+), 7 deletions(-)
---
base-commit: 8f5ae30d69d7543eee0d70083daf4de8fe15d585
change-id: 20250926-v9fs_misc-36320aef88d9

Best regards,
-- 
Dominique Martinet <asmadeus@codewreck.org>

