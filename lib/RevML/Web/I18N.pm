package RevML::Web::I18N;
use strict;
use base 'Locale::Maketext';

use Locale::Maketext::Lexicon {
    '*' => [Gettext => '/usr/local/share/locale/*/LC_MESSAGES/revmlweb.mo'],
    _decode => 1,
};

1;
