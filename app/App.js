import React, { Component } from 'react';
import {
  StyleSheet,
  Text,
  View
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
