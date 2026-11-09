From: Patrick Vogelaar <patrick.vogelaar@belden.com>
Subject: [PATCH 0/3] toaster: changes with regards to read-only log viewer
Date: Mon, 09 Nov 2026 08:46:36 +0100
Message-Id: <20261109-toaster-projects-nobuild-v1-0-7e65cadc2d39@belden.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFx68WoC/yXMQQqDMBBA0avIrDuQRLGlVyldmDhpp5REZqIUx
 Ls36vIt/l9BSZgU7s0KQgsr51RhLw2E95BehDxWgzOut9Z0WPKghQQnyR8KRTFlP/N3RO/a2F6
 70Edzg5pPQpF/x/rxPK2z35v9B9v2B9SfUF98AAAA
X-Change-ID: 20261104-toaster-projects-nobuild-b23f374c6f08
To: bitbake-devel@lists.openembedded.org
Cc: Patrick Vogelaar <patrick.vogelaar@belden.com>, 
 patrick.vogelaar.dev@mailbox.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794210409; l=3007;
 i=patrick.vogelaar@belden.com; s=20240201; h=from:subject:message-id;
 bh=VCr0jHm4/PNvKc7k52uK8u8JX9Pb+Vwb6LJyxkNolO8=;
 b=darhvCPqPTqyRmQ4Kf9cmSRY8vH3aUxWSM3tAltXj5Pb3K1VRXcC2kNRiMpBUMANvb0Jj1FlE
 GgEYENzHeV3AtZtBfwBv9Yb9Au0Ys6yV22/Lx9GVRF8HMr6rsAOy84N
X-Developer-Key: i=patrick.vogelaar@belden.com; a=ed25519;
 pk=w0QU8RmOR3hQv1DxMcz6KmySeE8yqbvO0xC1ZSSUNqY=
X-Endpoint-Received: by B4 Relay for patrick.vogelaar@belden.com/20240201 with auth_id=125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We use Toaster as a read-only build viewer for CI. Every CI build
uploads its bitbake event log to a shared Toaster instance, which
imports it with toaster-eventreplay and is started without build mode.
This works today, but has three limitations that this series removes:

* All imported builds land in the "Command line builds" project, so
  builds of differeent branches or CI instances cannot be told appart.
* Whithuot the build mode. projects are hard to reach because the
  "All projects" tab is hidden and project links lead to the configuration
  page for builds.
* And IMHO there was a bug that the time of the import instead of the
  actual start time.

Patch 1 shows projects and their builds without build mode and hides
the configuration pages and build actions there.

Patch 2 adds the TOASTER_PROJECT variable: if it is set, a command line
build or replayed event log goes into the project of that name, which
is created if needed. Without the variable nothing changes. It also
decides whether a build is a command line build from the absence of a
BuildRequest instead of from the default project, so command line
builds in named projects get no Rebuild/Cancel actions.

Patch 3 takes the build start and end time from the log and task
events, so a replayed log keeps the times of the original build. Live
builds are unchanged apart from at most a few seconds.

Signed-off-by: Patrick Vogelaar <patrick.vogelaar@belden.com>
---
Patrick Vogelaar (3):
      toaster: show projects and builds without build mode
      toaster: group command line builds by TOASTER_PROJECT
      toaster: take build times from the events

 bin/toaster                                        |   2 +-
 .../bitbake-user-manual-ref-variables.rst          |  13 ++
 lib/bb/ui/buildinfohelper.py                       |  54 +++++++--
 lib/bb/ui/toasterui.py                             |   1 +
 lib/toaster/tests/browser/test_all_builds_page.py  |   2 +
 lib/toaster/tests/buildinfohelper/__init__.py      |   0
 .../tests/buildinfohelper/test_build_time.py       |  62 ++++++++++
 .../tests/buildinfohelper/test_cli_project.py      | 131 +++++++++++++++++++++
 lib/toaster/tests/views/test_nobuild.py            |  94 +++++++++++++++
 lib/toaster/toastergui/templates/base.html         |   2 -
 .../toastergui/templates/basebuildpage.html        |   4 +
 lib/toaster/toastergui/templates/mrb_section.html  |   4 +-
 .../toastergui/templates/projecttopbar.html        |   2 +-
 .../toastergui/templatetags/project_url_tag.py     |  11 +-
 lib/toaster/toastergui/views.py                    |  13 ++
 lib/toaster/toastergui/widgets.py                  |   2 +-
 lib/toaster/tox.ini                                |   3 +-
 17 files changed, 378 insertions(+), 22 deletions(-)
---
base-commit: 0f33b68cbabab26c9ed1585e3ee109689d206812
change-id: 20261104-toaster-projects-nobuild-b23f374c6f08

Best regards,
--  
Patrick Vogelaar <patrick.vogelaar@belden.com>

