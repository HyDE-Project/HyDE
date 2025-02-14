import { opt } from 'variables/option'
import { APP_CONFIG } from 'lib/paths' 

export type Market =
  | 'random' | 'en-US' | 'ja-JP' | 'en-AU'
  | 'en-GB' | 'de-DE' | 'en-NZ' | 'en-CA'

export default {
  market: opt<Market>('random'),
  resolution: opt<1920 | 1366 | 3840>(1920),
  transitionType: opt<'grow' | 'wipe' | 'outer'>('wipe'),
  image: opt<string>(`${APP_CONFIG}/assets/wallpapers/nixos.png`),
}
