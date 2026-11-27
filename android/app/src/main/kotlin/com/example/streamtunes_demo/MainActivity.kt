package com.example.streamtunes_demo

import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity (de audio_service) en vez de FlutterActivity: comparte
// el motor de Flutter con el servicio de reproducción en segundo plano.
class MainActivity : AudioServiceActivity()
