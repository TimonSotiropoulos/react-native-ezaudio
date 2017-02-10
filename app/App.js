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

    testBridgeConnection = () => {
        console.log("JAvascript Button Log!");
        RNEZAudio.testBridgeConnection();
    };

    render() {
        return (
            <View style={styles.main}>
                <Button label={"PLAY"} onPress={this.testBridgeConnection} />
                <Button label={"STOP"} />
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
