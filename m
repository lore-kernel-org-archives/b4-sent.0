From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH 0/2] Polish module_directory help string, install symlinks
Date: Fri, 26 Jan 2024 14:43:49 +0000
Message-Id: <20240126-master-v1-0-6257d039a30a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACXFs2UC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDQyMz3dzE4pLUIl3TpEQjC7MkI7PU1BQloOKCotS0zAqwQdGxtbUAqZF
 WblgAAAA=
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706280230; l=807;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=Mwkjxdv6ZeI3RiGnQHQaNJvZizkxUrEbM4PzHrmVAGg=;
 b=owKXjQXevkD2k1BGeCmO+DPuJb+42URVekX0+uJqqAGxlaTkGo661qCftIJaRPj57Fbr07FD7
 hhY0BmaCUZ/DBUpVWRfoRGUUUZyedan1RNwvsKNrFMRC5vMPR2AqINq
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello all,

I've noticed the recent module_directory work and I'm super hyped to see
it released. Are there any plans for v32?

This tiny series has two patches:
 - tweaks the help string for the module_directory toggle
 - installs the insmod, rmmod, lsmod ... symlinks

The above should be fairly straightforward, but if there's any questions
or concerns do let me know.

Thanks
Emil

---
Emil Velikov (2):
      configure: tweak the module_directory help string
      make: install/uninstall tools symlinks to kmod

 Makefile.am  | 10 ++++++++++
 configure.ac |  2 +-
 2 files changed, 11 insertions(+), 1 deletion(-)
---
base-commit: 48b0c75f79f86140314b9656d3d855a515e18a73
change-id: 20240126-master-5ba286b26eed

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

