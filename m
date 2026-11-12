From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH 0/2] xfs/438: test the dquot retry again
Date: Thu, 12 Nov 2026 10:37:16 +0900
Message-Id: <20261112-xfs-438-dquot-retry-v1-0-73149b823246@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEwY9WoC/x2Myw5AMBAAf0X2bBNKpPEr4tDqLnvx2CJE/LvG3
 OYw80AkFYrQZg8onRJlmZOUeQbD5OaRUEJyMIVpygReHLGuLIbtWHZU2vVGH5itsc437CCVqxL
 L9V+7/n0/hFAkFGUAAAA=
To: Zorro Lang <zlang@kernel.org>, fstests@vger.kernel.org
Cc: "Darrick J. Wong" <djwong@kernel.org>, Christoph Hellwig <hch@lst.de>, 
 Brian Foster <bfoster@redhat.com>, Dave Chinner <dgc@kernel.org>, 
 linux-xfs@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794447436; l=977;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=E0VfzmCyAWgh/Gvr3G6DLo1ndFYwT69Y0tx9eVlLLBk=;
 b=ELg40/h4+AaY+cTKceRIrpCylbe44bs9h1gcrXH6nLKmlIurixHHSwmst3pk2xPJ0SildIS51
 kBpyH3DDcQVCf6fD2DUrs4OFsAdbjnJ1YPL+jPgIV9SWxq3KbDwWxMa
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Because fstests turns off metadata write retries for XFS scratch
mounts, xfs/438 passes on a kernel that has the bug. Its dm-flakey
table also relies on dm dropping a flush error, and the dm patch [1]
fixes that. Patch 1 turns the retries back on. Patch 2 moves the test
to the buf_ioerror error tag. Tested with an internal and an external
log on v7.4-rc2, with and without [1], and on a kernel with the bug
brought back.

[1] https://lore.kernel.org/r/20261112-dm-flush-data-error-v1-1-c83d3f8f3ac4@samsung.com

---
Daejun Park (2):
      xfs/438: retry failed metadata writes again
      xfs/438: fail metadata writes with the buf_ioerror error tag

 tests/xfs/438 | 89 ++++++++++++++---------------------------------------------
 1 file changed, 20 insertions(+), 69 deletions(-)
---
base-commit: 71641219a506ac62bfa231592394265ca812670e
change-id: 20261111-xfs-438-dquot-retry-bdff828ab6fa

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

