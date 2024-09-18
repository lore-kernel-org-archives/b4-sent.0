From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH 0/4] Backport statx(..., NULL, AT_EMPTY_PATH, ...)
Date: Wed, 18 Sep 2024 22:10:36 +0800
Message-Id: <20240918-statx-stable-linux-5-15-y-v1-0-5afb4401ddbe@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAFzf6mYC/x2Myw5AMBBFf0VmbaRF4/ErYlEMJpGSFqmIf1c2J
 znJPfcGR5bJQR3dYOlkx6sJIuMI+lmbiZCH4JCKNBeVLNHtevcfu4VwYXN4VCgVXljpTGSq1MW
 QFxD6zdLI/v9u4FRJGH0U0D7PC/8LDll4AAAA
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Mateusz Guzik <mjguzik@gmail.com>, 
 Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, linux-fsdevel@vger.kernel.org, 
 stable@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>, 
 Linus Torvalds <torvalds@linux-foundation.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2178;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=dkeHweZOsjkx3Ag5GOp8+zbO/oMVxglgz9oAsbZuWfw=;
 b=kA0DAAoBsDHjynv+2W4ByyZiAGbq32iiclsVGevsH3fdEUaojZ1rU7KBcrzo1/cYK142hpS/N
 YkCMwQAAQoAHRYhBESo9Y+A8kHGW57ME7Ax48p7/tluBQJm6t9oAAoJELAx48p7/tlu87gQANBX
 CdjnQ6MdfZkdWU82SRd8+3aRBEBWeQpcHyEmSxMxBWS/pXs21wtcl85ssdEtjpOnf8Ebfsz56R/
 VWbGkZFIsSpWJ42/34sAEBjK/g8wiZqNU1LSmyW9ZIq68P0qd6deZ4lTbAddNxIJLtugjEMw/9y
 LdevRi9NV66yNGF3saB/1poT0JjMuhA8kCiQiqrhfUEBnpgdaH3u4r08AwNWFXRyyIhtw9g4nOd
 J+bVssMyWn99MZ9kEfOgxxuxEjKR4j9MMcAWd2vIHVyCposnIneEOWVwDG26Fv2GRFwZE7AFEfZ
 D+MQui4jhJlXW04XcL2jC8mrThujD7DVxoWwCytqMAFXhpFNWV2a+hVPmLdjV9IuwSAVQ+g+P/A
 yjodgqh6fzEOrgwW3Ejm9SZEkTnztE0LoAP6uXLaPPxEJ8ze9t5iAru+32RElbfIhJqJz3XJ191
 /a1sgN9nlnHmf41EmybQ1EkRpzHrFJ2T4ob4wSTLUlWwewyGH97Swkl0J2fOSIr+e4VY6o3NmAC
 iA2SlvqYvtBHWYz2SMWJW52zrkB30LfAKslHWp5JG9rsaSDmDT4y//D+TA6lGUc3k9ha+mW3aje
 LnbwovzKdaMbwI1q1iJ4udI5yjYl/yPobc74u3l1jh34TvaZ1p+U2DHxW7yIGYhKE4nyMHoZE1g
 ZWRK+
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 0ef625bba6fb ("vfs: support statx(..., NULL, AT_EMPTY_PATH,
...)") added support for passing in NULL when AT_EMPTY_PATH is given,
improving performance when statx is used for fetching stat informantion
from a given fd, which is especially important for 32-bit platforms.
This commit also improved the performance when an empty string is given
by short-circuiting the handling of such paths.

This series is based on the commits in the Linus’ tree. Modifications
are applied to vfs_statx_path(). In the original patch, vfs_statx_path()
was created to warp around the call to vfs_getattr() after
filename_lookup() in vfs_statx(). Since the coresponding code is
different in 5.15 and 5.10, the content of vfs_statx_path() is modified
to match this. The original patch also moved path_mounted() from
namespace.c to internal.h, which is not applicable for 5.15 and 5.10
since it has not been introduced before 6.5. The original patch also
used CLASS(fd_raw, ) to convert a file descriptor number provided from
the user space in to a struct and automatically release it afterwards.
Since CLASS mechanism is only available since 6.1.79, obtaining and
releasing fd struct is done manually. do_statx() was directly handling
filename string instead of a struct filename * before 5.18, as a result
short-circuiting is implemented in do_statx() instead of sys_statx,
without the need of introducing do_statx_fd().

Tested-by: Xi Ruoyao <xry111@xry111.site>
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Christian Brauner (2):
      fs: new helper vfs_empty_path()
      stat: use vfs_empty_path() helper

Linus Torvalds (1):
      vfs: mostly undo glibc turning 'fstat()' into 'fstatat(AT_EMPTY_PATH)'

Mateusz Guzik (1):
      vfs: support statx(..., NULL, AT_EMPTY_PATH, ...)

 fs/stat.c          | 73 +++++++++++++++++++++++++++++++++++++++++++++---------
 include/linux/fs.h | 17 +++++++++++++
 2 files changed, 78 insertions(+), 12 deletions(-)
---
base-commit: 3a5928702e7120f83f703fd566082bfb59f1a57e
change-id: 20240918-statx-stable-linux-5-15-y-9a30358a7d47

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

