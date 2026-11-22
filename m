From: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Date: Sun, 22 Nov 2026 13:08:44 -0300
Subject: [PATCH 2/4] docs/translations/pt_BR: process: add
 maintainer-pgp-guide.rst (2/4)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261122-maintainer-pgp-guide-pt-br-v1-2-01ce5941c5c2@gmail.com>
References: <20261122-maintainer-pgp-guide-pt-br-v1-0-01ce5941c5c2@gmail.com>
In-Reply-To: <20261122-maintainer-pgp-guide-pt-br-v1-0-01ce5941c5c2@gmail.com>
To: linux-doc@vger.kernel.org
Cc: danielmaraboo@gmail.com, corbet@lwn.net, skhan@linuxfoundation.org, 
 rdunlap@infradead.org, Eduardo Pereira Cruz <dreduardocruz@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795363722; l=12372;
 i=dreduardocruz@gmail.com; s=20261119; h=from:subject:message-id;
 bh=C4iNQDl5JtYjV/glAd3couPQ1BGZQrblBzxgDjhFMcU=;
 b=KO9UUxX7WTBEsQV65uXXwCyc70pv7bk426265/H+3Ff9O3Zd0ljvLWMwz6q1W2YcLIxUXkrEW
 Cdyrx3tKhPmBzea3GsuMmFt4sm2/FeSiVDeM4GhupMeFyJjmsAJHOCE
X-Developer-Key: i=dreduardocruz@gmail.com; a=ed25519;
 pk=2dtL+BL/x70sROmAvlskv9dbjj274zlPkLBVu4gJJiA=
X-Endpoint-Received: by B4 Relay for dreduardocruz@gmail.com/20261119 with auth_id=1571
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Translate the rest of the key protection chapter: removing the Certify
key from the home directory, the keygrip handling and the details of
the private-keys-v1 directory.

Signed-off-by: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
---
 .../pt_BR/process/maintainer-pgp-guide.rst         | 249 +++++++++++++++++++++
 1 file changed, 249 insertions(+)

diff --git a/Documentation/translations/pt_BR/process/maintainer-pgp-guide.rst b/Documentation/translations/pt_BR/process/maintainer-pgp-guide.rst
index a4ec5c5ef83b..4e07d49e36d0 100644
--- a/Documentation/translations/pt_BR/process/maintainer-pgp-guide.rst
+++ b/Documentation/translations/pt_BR/process/maintainer-pgp-guide.rst
@@ -109,3 +109,252 @@ o arquivo ``~/.gnupg/gpg-agent.conf`` para definir os seus próprios valores::
 
 .. _protect_your_key:
 
+Proteja a sua chave PGP
+=======================
+
+Este guia pressupõe que você já tenha uma chave PGP usada para o
+desenvolvimento do kernel Linux. Se ainda não tiver uma, consulte o documento
+"`Protecting Code Integrity`_" mencionado anteriormente para orientação sobre
+como criar uma nova.
+
+Você também deve criar uma nova chave se a atual for mais fraca que 2048 bits
+(RSA).
+
+Entendendo as subchaves PGP
+----------------------------
+
+Uma chave PGP raramente consiste em um único par de chaves -- normalmente é uma
+coleção de subchaves independentes que podem ser usadas para propósitos
+diferentes, conforme as suas capacidades, atribuídas no momento da criação.
+O PGP define quatro capacidades que uma chave pode ter:
+
+- chaves **[S]** podem ser usadas para assinar
+- chaves **[E]** podem ser usadas para criptografar
+- chaves **[A]** podem ser usadas para autenticar
+- chaves **[C]** podem ser usadas para certificar outras chaves
+
+A chave com a capacidade **[C]** costuma ser chamada de chave "mestra", mas
+essa terminologia é enganosa porque implica que a chave de Certificação pode
+ser usada no lugar de qualquer outra subchave da mesma cadeia (como uma "chave
+mestra" física pode abrir fechaduras feitas para outras chaves). Como não é o
+caso, este guia se referirá a ela como "a chave de Certificação" para evitar
+ambiguidade.
+
+É fundamental entender completamente o seguinte:
+
+1. Todas as subchaves são totalmente independentes entre si. Se você perder
+   uma subchave privada, ela não pode ser restaurada nem recriada a partir de
+   qualquer outra chave privada da sua cadeia.
+2. Com exceção da chave de Certificação, pode haver várias subchaves com
+   capacidades idênticas (por exemplo, você pode ter 2 subchaves de
+   criptografia válidas, 3 subchaves de assinatura válidas, mas apenas uma
+   subchave de certificação válida). Todas as subchaves são totalmente
+   independentes -- uma mensagem criptografada para uma subchave **[E]** não
+   pode ser decifrada com qualquer outra subchave **[E]** que você também
+   tenha.
+3. Uma única subchave pode ter múltiplas capacidades (por exemplo, a sua
+   chave **[C]** também pode ser a sua chave **[S]**).
+
+A chave que carrega a capacidade **[C]** (certificar) é a única que pode ser
+usada para indicar relacionamento com outras chaves. Somente a chave **[C]**
+pode ser usada para:
+
+- adicionar ou revogar outras chaves (subchaves) com capacidades S/E/A
+- adicionar, alterar ou revogar identidades (uids) associadas à chave
+- adicionar ou alterar a data de expiração dela mesma ou de qualquer subchave
+- assinar chaves de outras pessoas para fins de teia de confiança
+
+Por padrão, o GnuPG cria o seguinte ao gerar novas chaves:
+
+- Uma subchave que carrega as capacidades de Certificação e Assinatura
+  (**[SC]**)
+- Uma subchave separada com a capacidade de Criptografia (**[E]**)
+
+Se você usou os parâmetros padrão ao gerar a sua chave, é isso que você terá.
+Você pode verificar executando ``gpg --list-secret-keys``, por exemplo::
+
+    sec   ed25519 2022-12-20 [SC] [expires: 2024-12-19]
+          000000000000000000000000AAAABBBBCCCCDDDD
+    uid           [ultimate] Alice Dev <adev@kernel.org>
+    ssb   cv25519 2022-12-20 [E] [expires: 2024-12-19]
+
+A linha longa sob a entrada ``sec`` é a impressão digital da sua chave --
+sempre que você vir ``[fpr]`` nos exemplos abaixo, é a essa string de 40 caracteres que a abreviação se refere.
+
+Garanta que a sua passphrase seja forte
+---------------------------------------
+
+O GnuPG usa passphrases para criptografar as suas chaves privadas antes de
+armazená-las em disco. Assim, mesmo que o seu diretório ``.gnupg`` vaze ou seja
+roubado por inteiro, os atacantes não podem usar as suas chaves privadas sem
+antes obter a passphrase para decifrá-las.
+
+É absolutamente essencial que as suas chaves privadas sejam protegidas por uma
+passphrase forte. Para defini-la ou alterá-la, use::
+
+    $ gpg --change-passphrase [fpr]
+
+Crie uma subchave de assinatura separada
+----------------------------------------
+
+Nosso objetivo é proteger a sua chave de Certificação movendo-a para mídia
+offline; portanto, se você tem apenas uma chave combinada **[SC]**, deve criar
+uma subchave de assinatura separada::
+
+    $ gpg --quick-addkey [fpr] ed25519 sign
+
+Faça backup da sua chave de Certificação para recuperação de desastres
+----------------------------------------------------------------------
+
+Quanto mais assinaturas de outros desenvolvedores você tiver na sua chave PGP de outros
+desenvolvedores, mais motivos você tem para criar uma versão de backup que
+viva em algo que não seja mídia digital, por razões de recuperação de
+desastres.
+
+Uma boa forma de criar uma cópia impressa da sua chave privada é usar o
+software ``paperkey``, escrito exatamente para esse propósito. Veja ``man
+paperkey`` para mais detalhes sobre o formato de saída e os seus benefícios em
+relação a outras soluções. O paperkey já deve estar empacotado para a maioria
+das distribuições.
+
+Execute o comando a seguir para criar um backup impresso da sua chave
+privada::
+
+    $ gpg --export-secret-key [fpr] | paperkey -o /tmp/key-backup.txt
+
+Imprima aquele arquivo e, com uma caneta, escreva a sua passphrase na margem
+do papel. **Isso é fortemente recomendado**, porque a impressão da chave
+ainda está criptografada com aquela passphrase e, se um dia você alterá-la,
+não vai se lembrar de qual era quando criou o backup -- *garantido*.
+
+Coloque a impressão resultante e a passphrase escrita à mão em um envelope e
+guarde em um lugar seguro e bem protegido, de preferência longe da sua casa,
+como um cofre de banco.
+
+.. note::
+
+    A chave ainda está criptografada com a sua passphrase, então imprimir até
+    em impressoras modernas "integradas à nuvem" deve continuar sendo uma
+    operação relativamente segura.
+
+Faça backup de todo o seu diretório GnuPG
+-----------------------------------------
+
+.. warning::
+
+    **!!!Não pule esta etapa!!!**
+
+É importante ter um backup prontamente disponível das suas chaves PGP
+caso precise recuperá-las. Isso é diferente da preparação para desastres que
+fizemos com o ``paperkey``. Você também dependerá dessas cópias externas sempre
+que precisar usar a sua chave de Certificação -- como ao fazer mudanças na sua
+própria chave ou ao assinar chaves de outras pessoas depois de conferências e
+summits.
+
+Comece obtendo um cartão de mídia externo (de preferência dois!) que você usará
+para fins de backup. Você precisará criar uma partição criptografada nesse
+dispositivo usando LUKS -- consulte a documentação da sua distro sobre como
+fazer isso.
+
+Para a passphrase de criptografia, você pode usar a mesma da sua chave PGP.
+
+Quando o processo de criptografia terminar, reinsira o dispositivo e garanta
+que ele seja montado corretamente. Copie todo o seu diretório ``.gnupg`` para
+o armazenamento criptografado::
+
+    $ cp -a ~/.gnupg /media/disk/foo/gnupg-backup
+
+Você deve agora testar para garantir que tudo ainda funciona::
+
+    $ gpg --homedir=/media/disk/foo/gnupg-backup --list-key [fpr]
+
+Se você não receber nenhum erro, está tudo certo. Desmonte o dispositivo,
+rotule-o de forma distinta para não sobrescrevê-lo por acidente e guarde-o em
+um lugar seguro -- mas não muito longe, porque você precisará usá-lo de vez em
+quando para coisas como editar identidades, adicionar ou revogar subchaves ou
+assinar chaves de outras pessoas.
+
+Remova a chave de Certificação do seu homedir
+---------------------------------------------
+
+Os arquivos no nosso diretório home não são tão bem protegidos quanto gostamos
+de pensar. Eles podem vazar ou ser roubados por muitos meios diferentes:
+
+- por acidente, ao fazer cópias rápidas do homedir para configurar uma nova
+  estação de trabalho
+- por negligência ou má-fé do administrador de sistemas
+- via backups mal protegidos
+- via malware em aplicativos de desktop (navegadores, leitores de pdf etc.)
+- via coerção ao cruzar fronteiras internacionais
+
+Proteger a sua chave com uma boa passphrase ajuda muito a reduzir o risco de
+qualquer um dos casos acima, mas passphrases podem ser descobertas via
+keyloggers, observação por cima do ombro ou qualquer número de outros meios.
+Por essa razão, a configuração recomendada é remover a sua chave de
+Certificação do diretório home e armazená-la em mídia offline.
+
+.. warning::
+
+    Consulte a seção anterior e garanta que você fez backup do seu diretório
+    GnuPG por inteiro. O que estamos prestes a fazer tornará a sua chave
+    inútil se você não tiver um backup utilizável!
+
+Primeiro, identifique o "keygrip" da sua chave de Certificação::
+
+    $ gpg --with-keygrip --list-key [fpr]
+
+A saída será algo como isto::
+
+    pub   ed25519 2022-12-20 [SC] [expires: 2022-12-19]
+          000000000000000000000000AAAABBBBCCCCDDDD
+          Keygrip = 1111000000000000000000000000000000000000
+    uid           [ultimate] Alice Dev <adev@kernel.org>
+    sub   cv25519 2022-12-20 [E] [expires: 2022-12-19]
+          Keygrip = 2222000000000000000000000000000000000000
+    sub   ed25519 2022-12-20 [S]
+          Keygrip = 3333000000000000000000000000000000000000
+
+Encontre a entrada de keygrip que está sob a linha ``pub`` (logo abaixo da
+impressão digital da chave de Certificação). Ela corresponderá diretamente a
+um arquivo no seu diretório ``~/.gnupg``::
+
+    $ cd ~/.gnupg/private-keys-v1.d
+    $ ls
+    1111000000000000000000000000000000000000.key
+    2222000000000000000000000000000000000000.key
+    3333000000000000000000000000000000000000.key
+
+Basta remover o arquivo .key correspondente ao keygrip da chave de
+Certificação::
+
+    $ cd ~/.gnupg/private-keys-v1.d
+    $ rm 1111000000000000000000000000000000000000.key
+
+Agora, se você emitir o comando ``--list-secret-keys``, ele mostrará que a
+chave de Certificação está ausente (o ``#`` indica que ela não está
+disponível)::
+
+    $ gpg --list-secret-keys
+    sec#  ed25519 2022-12-20 [SC] [expires: 2024-12-19]
+          000000000000000000000000AAAABBBBCCCCDDDD
+    uid           [ultimate] Alice Dev <adev@kernel.org>
+    ssb   cv25519 2022-12-20 [E] [expires: 2024-12-19]
+    ssb   ed25519 2022-12-20 [S]
+
+Você também deve remover quaisquer arquivos ``secring.gpg`` no diretório
+``~/.gnupg``, que podem ter sobrado de versões anteriores do GnuPG.
+
+Se você não tiver o diretório "private-keys-v1.d"
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+Se você não tiver um diretório ``~/.gnupg/private-keys-v1.d``, então as suas
+chaves secretas ainda estão armazenadas no arquivo legado ``secring.gpg``
+usado pelo GnuPG v1. Fazer qualquer mudança na sua chave, como alterar a
+passphrase ou adicionar uma subchave, deve converter automaticamente o formato
+antigo ``secring.gpg`` para usar ``private-keys-v1.d``.
+
+Depois de fazer isso, não deixe de excluir o arquivo ``secring.gpg`` obsoleto,
+que ainda contém as suas chaves privadas.
+
+.. _smartcards:
+

-- 
2.53.0

