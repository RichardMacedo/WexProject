import {ShowToastEvent} from "lightning/platformShowToastEvent";
import Error_Label from '@salesforce/label/c.Error';
import Success_Label from '@salesforce/label/c.Success';

/**
 * @description function to help with the notifications for the users and avoid boilerplate in the code
 * @param variant
 * @param message
 */
const LABELS = {
    ERROR : Error_Label,
    SUCCESS : Success_Label
};

const showToast = (variant, message, lwc, sticky) => {
    let mode = sticky ? 'sticky' : 'dismissible';

    lwc.dispatchEvent(
        new ShowToastEvent({"title" : (variant === 'error' ? 'Erro'  : variant === 'warning' ? 'Aviso' : 'Sucesso'), "message" : message, "variant" : variant, "mode" : mode})
    );
}

/**
 * @description formats a string by replacing the {0}, {1}, {2}, etc placeholders with the formattingArguments
 * @param stringToFormat
 * @param formattingArguments
 * @return {string}
 */
const formatLabel = (stringToFormat, ...formattingArguments) => {
    if (typeof stringToFormat !== 'string') throw new Error('\'stringToFormat\' must be a String');
    return stringToFormat.replace(/{(\d+)}/gm, (match, index) =>
        (formattingArguments[index] === undefined ? '' : `${formattingArguments[index]}`));
}

/**
 * @description parses the errors
 * @param errors
 * @returns {*|*[]}
 */
const parseErrors = (errors) => {
    if (Array.isArray(errors)) {
        return errors.map(e => e.message);
    } else {
        let errorArray = [];
        Object.keys(errors).forEach(error => {
            errorArray.push(errors[error].map(e => e.message));
        });
        return errorArray;
    }
}

/**
 * @description receives an error object/array/string and reduces them to a clean array of strings
 * @param errors
 * @returns {*}
 */
const reduceErrors = (errors) => {
    if (!Array.isArray(errors)) {
        errors = [errors];
    }
    return (
        errors
            // Remove null/undefined items
            .filter((error) => !!error)
            // Extract an error message
            .map((error) => {
                // UI API read errors
                if (Array.isArray(error.body)) {
                    return error.body.map((e) => e.message);
                }
                // UI API DML, Apex and network errors
                else if (error.body && typeof error.body.message === 'string') {
                    if (error.body.output && error.body.output.errors && error.body.output.errors.length) {
                        return parseErrors(error.body.output.errors);
                    }
                    return error.body.message;
                }
                // JS errors
                else if (typeof error.message === 'string') {
                    return error.message;
                }
                //APEX errors
                else if (error.body) {
                    if (
                        error.body.fieldErrors &&
                        (
                            (error.body.fieldErrors.constructor === Object && Object.keys(error.body.fieldErrors).length)
                            || (error.body.fieldErrors.length)
                        )
                    ) {
                        return parseErrors(error.body.fieldErrors);
                    } else if (error.body.pageErrors && error.body.pageErrors.length) {
                        return parseErrors(error.body.pageErrors);
                    }
                }
                // Unknown error shape so try HTTP status text
                return error.statusText;
            })
            // Flatten
            .reduce((prev, curr) => prev.concat(curr), [])
            // Remove empty strings
            .filter((message) => !!message)
    );
}

export {formatLabel, reduceErrors, showToast}