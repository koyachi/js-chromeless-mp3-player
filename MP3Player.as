package {
  import flash.display.*;
  import flash.text.*;
  import flash.net.URLRequest;
  import flash.media.Sound;
  import flash.media.SoundChannel;
  import flash.media.SoundTransform;
  import flash.external.ExternalInterface;
  import flash.events.*;
  import flash.errors.*;
  import flash.utils.*;

  public class MP3Player extends Sprite {
      public namespace external = 'http://buffr.org/as3/external';
      private var sound:Sound;
      private var soundChannel:SoundChannel;
      public var status:Object;
      private var eventCallbacks:Object = {};
      private var statusCodes:Object = {
          unstarted: -1,
          ended: 0,
          playing: 1,
          paused: 2,
          buffering: 3
      };

      public function MP3Player() {
          var text_field: TextField = new TextField();
          text_field.text = 'hello MP3Player';
          addChild(text_field);

          status = {
              msg: 'before loading',
              bytesLoaded: 0,
              bytesTotal: 0,
              seekPoint: 0,
              length: 0,
              isLoadComplete: false
          };

          var res:XMLList = describeType(this).method.(String(attribute('uri')) == external.uri);
          var methods:Array = [];
          for each (var n:* in res)
              methods.push(n.@name.toString());

          var self:* = this;
          for (var i:uint=0, length:uint=methods.length; i < length; i++) {
              ExternalInterface.addCallback(methods[i], self.external::[methods[i]]);
          }
          ExternalInterface.call('onChromelessMP3PlayerReady');
          onStateChange('unstarted');
      }

      external function addEventListener(eventName:String, funcName:String):void {
          log('addEventListener(' + eventName + ',' + funcName + ')');
          eventCallbacks[eventName] = funcName;
          log(eventCallbacks[eventName].toString());
      }
      external function load(url:String):void {
          log('load');
          this.external::stop();
          var req:URLRequest = new URLRequest(url);
          sound = new Sound(req);
          sound.addEventListener(Event.OPEN, evtSoundLoadingOpen);
          sound.addEventListener(ProgressEvent.PROGRESS, evtSoundLoadingProgress);
          sound.addEventListener(Event.COMPLETE, evtSoundLoadingComplete);
          sound.addEventListener(IOErrorEvent.IO_ERROR, evtSoundLoadingError);
          stage.addEventListener(Event.ENTER_FRAME, evtStageEnterFrame);
          onStateChange('buffering');
      }
      external function stop():void {
          log('stop');
          if (sound) {
              try {
                  this.external::pause();
                  if (status.isLoadComplete) {
                      status.isLoadComplete = false;
                      sound.close();
                  }
                  sound.removeEventListener(Event.OPEN, evtSoundLoadingOpen);
                  sound.removeEventListener(ProgressEvent.PROGRESS, evtSoundLoadingProgress);
                  sound.removeEventListener(Event.COMPLETE, evtSoundLoadingComplete);
                  sound.removeEventListener(IOErrorEvent.IO_ERROR, evtSoundLoadingError);
                  stage.removeEventListener(Event.ENTER_FRAME, evtStageEnterFrame);
                  status = {
                      msg: 'before loading',
                      bytesLoaded: 0,
                      bytesTotal: 0,
                      seekPoint: 0,
                      length: 0,
                      isLoadComplete: false
                  };
              }
              catch (error:IOError) {
                  log(['IOError on sound.close?',
                       error.errorID,
                       error.message,
                       error.name
                  ].join(' '));
              }
          }
      }
      external function play():void {
          log('play');
          this.external::pause();
          soundChannel = sound.play();
          onStateChange('playing');
      }
      external function pause():void {
          log('pause');
          if (soundChannel) soundChannel.stop();
          onStateChange('paused');
      }
      external function seekTo(seekTime:Number):void {
          log('seek to ' + seekTime);
          this.external::pause();
          if (seekTime > sound.length) {
              seekTime = sound.length;
              log('  seekTime was fixed to ' + seekTime);
          }         
          soundChannel = sound.play(seekTime);
      }
      external function getLoadingInfo():Object {
          return status;
      }
      external function getBytesLoaded():Number {
          return status.bytesLoaded;
      }
      external function getBytesTotal():Number {
          return status.bytesTotal;
      }
      external function getCurrentTime():Number {
          return status.seekPoint;
      }
      external function getDuration():Number {
          return status.length;
      }
      external function getVolume():Number {
          var volume:Number;
          if (soundChannel) {
              volume = soundChannel.soundTransform.volume
              return volume * 100;
          }
          else
              return 0;
      }
      external function setVolume(volume:Number):void {
          if (!soundChannel) return;
          if (volume > 100) volume = 100;
          if (volume < 0) volume = 0;
          var transform:SoundTransform = soundChannel.soundTransform;
          transform.volume = (volume != 0) ? volume / 100 : 0;
          soundChannel.soundTransform = transform;
      }

      private function onStateChange(state:String):void {
          log('AS.onStateChange')
          if (eventCallbacks['onStateChange']) {
              ExternalInterface.call(eventCallbacks['onStateChange'], statusCodes[state].toString());
          }
      }
      private function evtSoundLoadingOpen(event:Event):void {
          status.status = 'open';
          log(status.status);
      }
      private function evtSoundLoadingProgress(event:ProgressEvent):void {
          status.status = 'loading';
          status.bytesLoaded = event.bytesLoaded;
          status.bytesTotal = event.bytesTotal;
          log(status.status);
      }
      private function evtSoundLoadingComplete(event:Event):void {
          status.status = 'complete';
          status.isLoadComplete = true;
          log(status.status);
      }
      private function evtSoundLoadingError(event:IOErrorEvent):void {
          status.status = 'file IO error';
          log(status.status);
      }
      private function evtStageEnterFrame(event:Event):void {
          status.seekPoint = soundChannel.position;
          status.length = sound.length;
          if (status.length > 1000 && status.seekPoint >= (status.length - 1000)) {
              if (status.status != 'ended') {
                  onStateChange('ended');
              }
              status.status = 'ended';
          }
      }

      private function log(msg:String):void {
//          ExternalInterface.call('log', msg);
      }
  }
}
