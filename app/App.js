import React, { Component } from 'react';
import {
  StyleSheet,
  Text,
  View,
  NativeAppEventEmitter,
} from 'react-native';

import Button from './components/Button';

import { NativeModules } from 'react-native';
const RNEZAudio = NativeModules.RNEZAudio;


export default class App extends Component {
    constructor(props) {
        super(props);
    }

    componentDidMount() {
        console.log("Initting Audio Engine!");
        RNEZAudio.initAudioEngine();

        this.volumeUpdateListener = NativeAppEventEmitter.addListener('VolumeUpdate', (data) => {
            console.log("Volume update data received: " + data.volumeData);
        });

        this.FFTUpdateListener = NativeAppEventEmitter.addListener('FFTUpdate', (data) => {
            console.log("FFT update data received:");
            console.log(data.fftData[0]);
            console.log(data.fftData[1]);
            console.log(data.fftData[2]);
        });
    }

    componentWillUnmount() {
        this.volumeUpdateListener.remove();
    }

    testBridgeConnection = () => {
        console.log("JAvascript Button Log!");
        RNEZAudio.testBridgeConnection();
    };

    startRecording = () => {
        RNEZAudio.startRecording();
    };

    stopRecording = () => {
        RNEZAudio.stopRecording();
    }

    render() {
        return (
            <View style={styles.main}>
                <Button label={"RECORD"} onPress={this.startRecording} />
                <Button label={"PLAY"} onPress={this.testBridgeConnection} />
                <Button label={"STOP"} onPress={this.stopRecording} />
            </View>
        );
    }
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center'
    }
});
