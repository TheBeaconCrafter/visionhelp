/*
____   ____.__       .__                  ___ ___         .__          
\   \ /   /|__| _____|__| ____   ____    /   |   \   ____ |  | ______  
 \   Y   / |  |/  ___/  |/  _ \ /    \  /    ~    \_/ __ \|  | \____ \ 
  \     /  |  |\___ \|  (  <_> )   |  \ \    Y    /\  ___/|  |_|  |_> >
   \___/   |__/____  >__|\____/|___|  /  \___|_  /  \___  >____/   __/ 
                   \/               \/         \/       \/     |__|    
*/

const String geminiApiKey = 'YOURAPIKEY'; //API Key for Gemini
const String botToken = 'YOURBOTTOKEN'; //API Key for Telegram

/// Address book for Telegram
// Remember that this is just a proof of concept, thats why I didnt implement a full contact book yet
var addressBook = {
  'friendname': '1234567890',
  'friend2': '1234567890',
  // Add more entries as needed
  //These are Telegram IDs, not phone numbers
};