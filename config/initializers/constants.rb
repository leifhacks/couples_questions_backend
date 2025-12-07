# frozen_string_literal: true

LINKS = {
  ios_production_verification: 'https://buy.itunes.apple.com/verifyReceipt',
  ios_sandbox_verification: 'https://sandbox.itunes.apple.com/verifyReceipt'
}.freeze

THUMBNAIL_SIZE = 240
IMAGE_BASE_PATH = '/mnt/images'
IMAGES_SUB_DIR = 'user_content'

NOTIFICATION_TEXT_FOR_PARTNER = {
  'de' => [
    'Dein Partner hat die heutige Frage beantwortet.',
    'Beantworte selbst die Frage, um die Antwort zu sehen.'
  ],
  'en' => [
    "Your partner answered today's question.",
    'Answer yourself to see what your partner said.'
  ]
}.freeze

NOTIFICATION_TEXT_FOR_USER = {
  'de' => [
    'Dein Partner hat die heutige Frage beantwortet.',
    'Öffne die App, um die Antwort zu sehen.'
  ],
  'en' => [
    "Your partner answered today's question.",
    'Open the app to see what your partner said.'
  ]
}.freeze