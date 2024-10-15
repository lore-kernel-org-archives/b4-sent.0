From: Daniel Gomez <da.gomez@samsung.com>
Subject: [PATCH 0/2] MAINTAINERS: add support
Date: Wed, 16 Oct 2024 00:28:53 +0200
Message-Id: <20241016-add-maintainers-file-v1-0-77909845c782@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKXsDmcC/x2MywqAIBAAf0X23IKP8tCvRAfLrRbKQiMC8d+TD
 nOYw0yGRJEpQS8yRHo48RmqqEbAvLmwErKvDlrqVknVofMeD8fhrlBMuPBOaNvZTdbIThsNNb0
 iLfz+22Es5QMuY0U4ZgAAAA==
X-Change-ID: 20241015-add-maintainers-file-64cab6305232
To: Luis Chamberlain <mcgrof@kernel.org>
Cc: linux-kdevops@linux.dev, "Daniel Gomez (Samsung)" <d@kruces.com>, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729031349; l=1727;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=+/DH79qlcRlN1TpVnK/qLRJOOIgZMvYQMcvgSX9OEuI=;
 b=sxEivODsg7piTCjQ+sqT7Sfvxt/VFRHKyUjmx2nu+fr80ra/YX3h9BlUJHASRQVGfbdPa5cPT
 n0P/ZL+cWL+Bx1dYLzrro5IeNhx3xF8rtrp0qtefhfJ401SuCsbXYwA
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This introduces support for the MAINTAINERS file (with the same Linux
kernel syntax), get_maintainers.pl, and the b4 configuration file.

With these changes, the MAINTAINERS file can now be used to organize and
manage maintainers, reviewers, and other roles more effectively, similar
to the approach used in the Linux kernel. Additionally, it allows for
reuse of the existing tooling for these tasks (b4 + get_maintainers.pl).

b4 example workflow:

  b4 prep --fork-point origin/main --new add-MAINTAINERS-file

  b4 prep --edit-cover

  b4 prep --auto-to-cc
  Will collect To: addresses using get_maintainer.pl
  Will collect Cc: addresses using get_maintainer.pl
  Collecting To/Cc addresses
      + To: Luis Chamberlain <mcgrof@kernel.org>
      + Cc: linux-kdevops@linux.dev
  ---
  You can trim/expand this list with: b4 prep --edit-cover
  Invoking git-filter-repo to update the cover letter.
  New history written in 0.02 seconds...
  Completely finished after 0.06 seconds

  b4 send

More information can be found here:
https://b4.docs.kernel.org/en/latest/contributor/
overview.html#what-s-the-b4-contributor-workflow

Suggestions on how to split the MAINTAINERS file?

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
Daniel Gomez (2):
      MAINTAINERS: add support
      .b4-config: add b4 support

 .b4-config                |    3 +
 MAINTAINERS               |   76 ++
 scripts/get_maintainer.pl | 2642 +++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 2721 insertions(+)
---
base-commit: 94e53a6ba38432d211711b8eae1da6545c682f84
change-id: 20241015-add-maintainers-file-64cab6305232

Best regards,
-- 
Daniel Gomez <da.gomez@samsung.com>

