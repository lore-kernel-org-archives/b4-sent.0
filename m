From: Luca Stefani <luca.stefani.ge1@gmail.com>
Subject: [PATCH 0/2] btrfs: don't expose ERESTARTSYS to userspace
Date: Wed, 28 Oct 2026 18:55:48 +0100
Message-Id: <20261028-b4-btrfs-fitrim-interruption-v1-0-bf5c53738b3a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WNwQrCMBBEf6Xs2cUkVA3+inhI0o1dwbRsUimU/
 ruJnjy+YebNBpmEKcO120DozZmnVEEfOgijSw9CHiqDUeaslbHoe/RFYsbIRfiFnAqJLHOpQ+y
 to8vJKh2dgqqYhSKvX/3t/uO8+CeF0pyt4V0m9OJSGFsUpoHW499Ba8C+fwD6eobCqgAAAA==
X-Change-ID: 20261028-b4-btrfs-fitrim-interruption-48ae75801fa0
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>, 
 Luca Stefani <luca.stefani.ge1@gmail.com>
Cc: Robbie Ko <robbieko@synology.com>, Filipe Manana <fdmanana@suse.com>, 
 linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Zhiwei Liang <zhiwei.liang@zliang.me>, Qu Wenruo <wqu@suse.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793210149; l=774;
 i=luca.stefani.ge1@gmail.com; s=20261028; h=from:subject:message-id;
 bh=LP4DYsLlDaDdL3BoYv5vWPMKYJ6s1RRwL4P6KPDAzyQ=;
 b=uIUbdgWZ2fNLrejSX67UdUxqI1ETM6ecJqN4cAjl7NEPosiANqjvj85RUUh0BRBtDgpo9orL2
 allb0rgwTrPDbujmi1NtLaPeza3YnHEno2ybDI1XYTb4fsRsDDDnXbk
X-Developer-Key: i=luca.stefani.ge1@gmail.com; a=ed25519;
 pk=0OIKU9oiaC0ALN4kqvw7ZbPFXqsBLvWm7MhEDYv3PyI=
X-Endpoint-Received: by B4 Relay for luca.stefani.ge1@gmail.com/20261028 with auth_id=1347
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

trim can expose -ERESTARTSYS when the trim loops gets interrupted by
a freezer request.

Preserve byte counts of partially completed discards.
Consume cancellation at btrfs_trim_fs(), and report partial progress.

Link: https://lore.kernel.org/20261028-btrfs-fitrim-freezer-v1-1-0ad1d58aa94d@zliang.me/
---
Luca Stefani (2):
      btrfs: account partially completed discards
      btrfs: don't report failure when trim is interrupted

 fs/btrfs/extent-tree.c      | 10 ++++------
 fs/btrfs/free-space-cache.c |  5 ++---
 2 files changed, 6 insertions(+), 9 deletions(-)
---
base-commit: 65ba8f34ec886ec72b2c07ddc8cf3d815c32869d
change-id: 20261028-b4-btrfs-fitrim-interruption-48ae75801fa0

Best regards,
--  
Luca Stefani <luca.stefani.ge1@gmail.com>

